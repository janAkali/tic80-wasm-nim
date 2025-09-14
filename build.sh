#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

[[ -d "./build" ]] && rm ./build/*
nim c $@ -o:build/main.wasm src/main.nim

tic80 --cli \
      --fs="$SCRIPT_DIR/build" \
      --cmd="load ../wasm_base.tic & import binary main.wasm & save game.tic & exit"
tic80 --skip --fs="$SCRIPT_DIR/build" --cmd="load game & run"
