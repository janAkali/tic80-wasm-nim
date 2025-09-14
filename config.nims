from std/os import `/`

let wasi = getEnv("WASI_SDK_PATH")
if wasi == "" and not defined(nimsuggest):
  echo ""
  echo "Error:"
  echo "Download the WASI SDK (https://github.com/WebAssembly/wasi-sdk) and set the $WASI_SDK_PATH environment variable!"
  echo ""
  quit(-1)

switch("path", "." / "src") # so demos could find `api/tic80` import

switch("cc", "clang")
switch("clang.exe", wasi / "bin" / "clang")
switch("clang.linkerexe", wasi / "bin" / "clang")

switch("os", "any")        # wasm is linux-like
switch("cpu", "wasm32")    # Target WebAssembly 32-bit
switch("gc", "arc")        # ARC is much more embedded-friendly
switch("threads", "off")   # WebAssembly doesn't support threads

switch("define", "posix")            # needed for --os:any
switch("define", "noSignalHandler")  # WASM has no signal handlers
switch("define", "useMalloc")        # Use system malloc for smaller binary
switch("noMain")                     # The only entrypoints are TIC and BOOT

switch("passC", "--sysroot=" & (wasi / "share" / "wasi-sysroot"))
switch("passL", "-Wl,-zstack-size=8192,--no-entry,--import-memory")
switch("passL", "-Wl,--initial-memory=262144,--max-memory=262144,--global-base=98304")
switch("passL", "-mexec-model=reactor")

when defined(release):
  switch("opt", "size")
  switch("panics", "on")     # Treat defects as errors for smaller binary
  switch("passC", "-flto")
  switch("passL", "-Wl,--strip-all,--gc-sections,--lto-O3") # removes unused Nim functions
else:
  switch("passL", "-Wl,--gc-sections")

  # From WASM-4 template. Breaks print debugging, so it's off by default.
  # switch("assertions", "off")
  # switch("checks", "off")
  # switch("stackTrace", "off")
  # switch("lineTrace", "off")
  # switch("lineDir", "off")
  # switch("debugger", "native")
