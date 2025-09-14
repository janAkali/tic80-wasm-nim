# Package

version       = "0.2.0"
author        = "JanAkali"
description   = "TIC-80 WASM Template"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"

# Tasks

from std/os import commandLineParams, `/`

proc argsAfterTask(name: string): seq[string] =
  let args = commandLineParams()
  for i in 0 ..< args.len:
    if args[i].cmpIgnoreStyle(name) == 0:
      return args[i+1 .. ^1]

proc verboseExec(cmd: string) =
  echo "Exec: " & cmd
  exec cmd

proc cleanup() =
  rmFile "build" / "main.wasm"
  rmFile "build" / "game.tic"

task buildwasm, "Build wasm binary":
  cleanup()
  verboseExec("nim c " & argsAfterTask("buildwasm").join" " & " -o:build/main.wasm src/main.nim")

task buildgame, "Build game cartridge and exit":
  cleanup()
  verboseExec("nim c " & argsAfterTask("buildgame").join" " & " -o:build/main.wasm src/main.nim")
  verboseExec("tic80 --cli --fs=\"$PWD/build\" --cmd=\"load ../src/main.tic & import binary main.wasm & save game.tic & exit\"")

task rungame, "Build game cartridge and launch it with tic80":
  cleanup()
  verboseExec("nim c " & argsAfterTask("rungame").join" " & " -o:build/main.wasm src/main.nim")
  verboseExec("tic80 --skip --fs=\"$PWD/build\" --cmd=\"load ../src/main.tic & import binary main.wasm & save game.tic & run\"")
