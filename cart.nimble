# Package

version       = "0.1.0"
author        = "archargelod"
description   = "tic80 wasm template for Nim language"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"

# Tasks

task wasmbuild, "Build wasm binary from Nim code":
  exec("nim c -o:cart.wasm src/cart")

task wasmrelease, "Build wasm binary from Nim code (optimized)":
  exec("nim c -d:release -o:cart.wasm src/cart")

task buildcart, "Build wasm binary from Nim code and import it to tic80 cart":
  exec("nim c -d:release -o:cart.wasm src/cart")
  rmFile("cart.tic")
  exec("tic80 --cli --fs=\"$PWD\" --cmd=\"load src/cart.tic & import binary cart.wasm & save cart.tic & exit\"")
