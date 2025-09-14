#!/usr/bin/env bash
set -e

TARGET_DIR="$(realpath ${@:-src})"
cd $TARGET_DIR

nim c -d:release -o:main.wasm main.nim
tic80 --skip \
      --fs="$TARGET_DIR" \
      --cmd="load main.tic & import binary main.wasm & save & run"

rm -rf .local
