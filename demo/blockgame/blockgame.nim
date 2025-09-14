import api/tic80
import std/[sequtils, strutils, tables, random]

const
  TileWT = 6
  TileHT = 6
  WellWT = 10
  WellHT = 22

  BindTimerReset = 15

type
  Vec2 = tuple[x,y: int32]
  Tile = int
  Score = int

  GameState = enum Prepare, Fall, Bind, Lock, Clear, GameOver
  RotState = enum Spawn, Right, Mirror, Left
  Tetramino = enum L, J, S, Z, T, O, I

  Well = object
    tiles: array[WellHT, array[WellWT, Tile]]
  Piece = object
    pos: Vec2
    piece: Tetramino
    rotation: RotState
    tiles: seq[seq[Tile]]
  Sack = object
    index: range[0 .. 20]
    pieces: array[21, int32]

const
  WellOrigin: Vec2 = (89, 2)
  ScoreOrigin: Vec2 = (155, 10)
  Pieces = [
    (L, @[@[1,0,0],
          @[1,1,1],
          @[0,0,0]]),
    (J, @[@[0,0,2],
          @[2,2,2],
          @[0,0,0]]),
    (S, @[@[0,3,3],
          @[3,3,0],
          @[0,0,0]]),
    (Z, @[@[4,4,0],
          @[0,4,4],
          @[0,0,0]]),
    (T, @[@[0,5,0],
          @[5,5,5],
          @[0,0,0]]),
    (O, @[@[6,6],
          @[6,6]]),
    (I, @[@[0,0,0,0],
          @[7,7,7,7],
          @[0,0,0,0],
          @[0,0,0,0]]),
  ]

  WallKicks3x3 = {
    (Spawn,Right):[(0'i32,0'i32),(-1,0),(-1, 1), (0,-2), (-1,-2)],
    (Right,  Spawn ): [(0, 0), ( 1, 0), ( 1,-1), (0, 2), ( 1, 2)],
    (Right,  Mirror): [(0, 0), ( 1, 0), ( 1,-1), (0, 2), ( 1, 2)],
    (Mirror, Right ): [(0, 0), (-1, 0), (-1, 1), (0,-2), (-1,-2)],
    (Mirror, Left  ): [(0, 0), ( 1, 0), ( 1, 1), (0,-2), ( 1,-2)],
    (Left,   Mirror): [(0, 0), (-1, 0), (-1,-1), (0, 2), (-1, 2)],
    (Left,   Spawn ): [(0, 0), (-1, 0), (-1,-1), (0, 2), (-1, 2)],
    (Spawn,  Left  ): [(0, 0), ( 1, 0), ( 1, 1), (0,-2), ( 1,-2)],
  }.toTable()

  WallKicksI = {
    (Spawn,Right):[(0'i32,0'i32),(-2,0),(1 , 0), (-2, -1), ( 1,  2)],
    (Right,  Spawn ): [(0, 0), ( 2, 0), (-1, 0), ( 2,  1), (-1, -2)],
    (Right,  Mirror): [(0, 0), (-1, 0), ( 2, 0), (-1,  2), ( 2, -1)],
    (Mirror, Right ): [(0, 0), ( 1, 0), (-2, 0), ( 1, -2), (-2,  1)],
    (Mirror, Left  ): [(0, 0), ( 2, 0), (-1, 0), ( 2,  1), (-1, -2)],
    (Left,   Mirror): [(0, 0), (-2, 0), ( 1, 0), (-2, -1), ( 1,  2)],
    (Left,   Spawn ): [(0, 0), ( 1, 0), (-2, 0), ( 1, -2), (-2,  1)],
    (Spawn,  Left  ): [(0, 0), (-1, 0), ( 2, 0), (-1,  2), ( 2, -1)],
  }.toTable()

  LevelSpeed = [48, 43, 38, 33, 28, 23, 18, 13,
                8, 6, 5, 5, 5, 4, 4, 4, 3, 3, 3,
                2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1]

proc next(r: RotState): RotState = (if r == Left: Spawn else: r.succ)
proc prev(r: RotState): RotState = (if r == Spawn: Left else: r.pred)

proc isObstructed(p: Piece, w: Well, d: Vec2 = (0, 0)): bool =
  for ty, row in p.tiles:
    for tx, tile in row:
      if tile == 0: continue
      let (x, y) = (p.pos.x + tx + d.x, p.pos.y + ty + d.y)
      if x < 0 or x > WellWT-1 or y < 0 or y > WellHT-1: return true
      if w.tiles[y][x] != 0: return true

proc isGameOver(w: Well): bool =
  for y in countdown(w.tiles.high-20, 0):
    for x in 0 .. w.tiles[0].high:
      if w.tiles[y][x] != 0: return true

proc rotcw(s: seq[seq[Tile]]): seq[seq[Tile]] =
  result = newSeqWith(s.len, newSeq[Tile](s.len))
  for i in 0..<result.len:
    for j in 0..<result.len:
      result[j][result.len-i-1] = s[i][j]

proc rotccw(s: seq[seq[Tile]]): seq[seq[Tile]] =
  result = newSeqWith(s.len, newSeq[Tile](s.len))
  for i in 0..<result.len:
    for j in 0..<result.len:
      result[result.len-j-1][i] = s[i][j]

proc rotate(p: var Piece, w: Well, cw = true): bool =
  if p.piece == O: return true
  var temp = p
  if cw:
    temp.tiles = p.tiles.rotcw
    temp.rotation = p.rotation.next
  else:
    temp.tiles = p.tiles.rotccw
    temp.rotation = p.rotation.prev
  let rotPair = (p.rotation, temp.rotation)
  for delta in (if p.piece == I: WallKicksI[rotPair] else: WallKicks3x3[rotPair]):
    if not temp.isObstructed(w, delta):
      temp.pos.x += delta[0]
      temp.pos.y += delta[1]
      p = temp
      return true

proc move(f: var Piece, w: Well, d: Vec2): bool =
  if not f.isObstructed(w, d):
    f.pos.x += d[0]
    f.pos.y += d[1]
    return true

proc draw(p: Piece) =
  let forigin: Vec2 = (WellOrigin.x + p.pos.x * TileWT , WellOrigin.y + p.pos.y * TileHT)
  for y, row in p.tiles:
    for x, tile in row:
      if tile == 0: continue
      spr(tile, forigin.x + TileWT * x, forigin.y + TileHT * y, transColor=Color0)
  # rectb(forigin.x - 1, forigin.y - 1, f.tiles[0].len * TileWT + 2, f.tiles.len * TileHT + 2, Color5)

proc draw(w: Well) =
  for y, row in w.tiles:
    for x, tile in row:
      spr(tile, WellOrigin.x + TileWT * x, WellOrigin.y + TileHT * y, transColor=Color0)
  rect(WellOrigin.x, WellOrigin.y + ((WellHT - 20) * TileHT) - 1, WellWT * TileWT, 1, Color2)
  rectb(WellOrigin.x - 1, WellOrigin.y - 1, WellWT * TileWT + 2, WellHT*TileHT + 2, Color12)

proc newSack(): Sack =
  for i in 0 .. result.pieces.high:
    result.pieces[i] = i mod Pieces.len
  result.pieces.shuffle()

proc getNewPiece(sack: var Sack): Piece =
  let (piece, tiles) = Pieces[sack.pieces[sack.index]]
  if sack.index == sack.pieces.high:
    sack.index = 0
    sack.pieces.shuffle()
  else: inc sack.index
  Piece(pos: (4, 0), tiles: tiles, piece: piece)

proc embed(p: Piece, w: var Well) =
  for ty, row in p.tiles:
    for tx, tile in row:
      if tile == 0: continue
      w.tiles[p.pos.y + ty][p.pos.x + tx] = tile

proc clearLines(w: var Well): int =
  var temp = Well()
  var ty = temp.tiles.high

  for y in countdown(w.tiles.high, 0):
    var complete = true
    for x in 0..w.tiles[y].high:
      if w.tiles[y][x] == 0:
        complete = false
        break

    if not complete:
      temp.tiles[ty] = w.tiles[y]
      if ty != 0: dec ty
    else:
      inc result

  w = temp

type Sound = enum Click, SLock, SClear
proc playSound(s: Sound) =
  const args = [
    (1, 5, 4,  3, 0,  8,  8,  0), # Click
    (2, 3, 3, -1, 1,  8,  8,  0), # Lock
    (4, 0, 4, 30, 2, 12, 12, -1), # Clear
  ]
  let (sfx_id, note, octave, duration, channel, volume_left, volume_right, speed) = args[s.int]
  sfx(sfx_id, note, octave, duration, channel, volume_left, volume_right, speed)


randomize(int64 tstamp())

var score: Score = 0
var level = 1
var linesCleared = 0
var well = Well()
var sack = newSack()
var piece: Piece
var gameState = Prepare

var fallSpeed = LevelSpeed[level]
var fallTimer = 0
var bindTimer = BindTimerReset

proc reset =
  score = 0
  level = 1
  linesCleared = 0
  well = Well()
  sack = newSack()
  gameState = Prepare
  fallSpeed = LevelSpeed[level]
  fallTimer = 0
  bindTimer = BindTimerReset

proc drawAll() =
  cls(Color15)
  well.draw()

  if gameState in {Lock, Clear}:
    rectb(WellOrigin.x - 1, WellOrigin.y - 1, WellWT * TileWT + 2, WellHT*TileHT + 2, Color6)

# next piece
  rect( WellOrigin.x - (6 * TileWt) - 1, WellOrigin.y - 1, 6 * TileWT - 1, 5 * TileHT, Color14)
  rectb(WellOrigin.x - (6 * TileWt) - 1, WellOrigin.y - 1, 6 * TileWT - 1, 5 * TileHT, Color12)
  draw Piece(pos: (-5, 2), tiles: Pieces[sack.pieces[sack.index]][1])
  print("NEXT", WellOrigin.x - (6 * TileWt) + 2, WellOrigin.y + 2, Color12)

  piece.draw()
  print("Level: " & $level, ScoreOrigin.x, ScoreOrigin.y, Color12, fixed = true)
  print("Score: " & $score, ScoreOrigin.x, ScoreOrigin.y + 6, Color12, fixed = true)

  if gameState == GameOver:
    print("GAME OVER!", 0, Height - 12, Color2)
    print("X/A to restart", 0, Height - 6, Color2)

proc main =
  if gameState in {Fall, Bind}:
    if btnp(P1_Up, 5, 10):
      for _ in 0..WellHT: discard piece.move(well, ( 0'i32, 1'i32))
      if not piece.move(well, ( 0'i32, 1'i32)): gameState = Lock
    if btnp(P1_Down , 5, 2):
      if not piece.move(well, (0'i32, 1'i32)): gameState = Bind
      else: fallTimer = 0
    if btnp(P1_Left , 5, 10): discard piece.move(well, (-1'i32,  0'i32)); playSound(Click)
    if btnp(P1_Right, 5, 10): discard piece.move(well, ( 1'i32,  0'i32)); playSound(Click)

    if btnp(P1_A, 5, 10): discard piece.rotate(well, cw = false); playSound(Click)
    if btnp(P1_B, 5, 10): discard piece.rotate(well, cw = true); playSound(Click)

  case gameState
  of Prepare:
    piece = sack.getNewPiece()
    fallTimer = 0
    bindTimer = BindTimerReset
    gameState = Fall
  of Fall:
    inc fallTimer
    if fallTimer mod fallSpeed == 0:
      if not piece.move(well, (0'i32,  1'i32)): gameState = Bind
  of Bind:
    dec bindTimer
    if bindTimer <= 0:
      if not piece.move(well, (0'i32,  1'i32)): gameState = Lock
      else: gameState = Fall
  of Lock:
    playSound(SLock)
    piece.embed(well)
    gameState = Clear

    if isGameOver(well): gamestate = GameOver
  of Clear:
    let lines = well.clearLines()
    linesCleared += lines
    score += lines*lines * 250
    if lines > 0: playSound(SClear)
    if lines > linesCleared mod 10:
      inc level
      fallSpeed = LevelSpeed[level]
    gameState = Prepare
  of GameOver:
    if btnp(P1_X, 5): reset()

  drawAll()

proc TIC {.exportWasm.} =
  try:
    main()
  except Exception as e:
    trace("Traceback (most recent call last)")
    var stackTrace = getStackTrace(e)
    if stackTrace.len > 0:
      for line in stackTrace.splitLines():
        if line.len > 0:
          trace(line.cstring)

    trace(cstring "Error: " & $e.name & ": " & e.msg)
    texit()
