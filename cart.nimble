# Package

version       = "0.2.1"
author        = "JanAkali"
description   = "TIC-80 WASM Template"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"

# Tasks

from std/os import commandLineParams, `/`
from std/strformat import `&`

proc argsAfterTask(name: string): seq[string] =
  let args = commandLineParams()
  for i in 0 ..< args.len:
    if args[i].cmpIgnoreStyle(name) == 0:
      return args[i+1 .. ^1]

proc verboseExec(cmd: string) =
  echo "Exec: " & cmd
  exec cmd

proc startup() =
  mkDir "build"
  rmFile "build" / "main.wasm"
  rmFile "build" / "main.tic"

task editcart, "Open base cartridge with Tic-80 internal editor":
  startup()
  verboseExec(&"tic80 --skip --fs=\"{getCurrentDir()}/build\" --cmd=\"load ../src/main.tic & edit\"")

task buildcart, "Build Tic-80 cartridge":
  startup()
  verboseExec("nim c " & argsAfterTask("buildcart").join" " & " -o:build/main.wasm src/main.nim")
  verboseExec(&"tic80 --cli --fs=\"{getCurrentDir()}/build\" --cmd=\"load ../src/main.tic & import binary main.wasm & save main.tic & exit\"")

task runcart, "Build Tic-80 cartridge and launch it":
  startup()
  verboseExec("nim c " & argsAfterTask("runcart").join" " & " -o:build/main.wasm src/main.nim")
  verboseExec(&"tic80 --skip --fs=\"{getCurrentDir()}/build\" --cmd=\"load ../src/main.tic & import binary main.wasm & save main.tic & run\"")
