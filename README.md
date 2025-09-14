# TIC80-WASM-Nim

**TIC80-WASM-Nim** is a template for building TIC-80 WASM carts using the Nim programming language.

## Getting Started

Follow the steps below to set up the project.

### Prerequisites

- [WASI-SDK](https://github.com/WebAssembly/wasi-sdk) anywhere on your system.
- [TIC-80](https://tic80.com/) added to your system's `PATH`.
- [Nim](https://nim-lang.org/) compiler.

### Installation

1. Clone the repository:
   ```bash
   git clone https://codeberg.org/janakali/tic80-wasm-nim
   cd tic80-wasm-nim
   ```

2. Set the `WASI_SDK_PATH` environment variable to the location of WASI-SDK:
   ```bash
   export WASI_SDK_PATH=/path/to/wasi-sdk
   ```

3. Verify that `tic80` is available in your `PATH`:
   ```bash
   tic80 --version
   ```

### Build

1. Edit game code in `src/cart.nim`.
2. Edit base cart in `assets/wasm_base.tic` to change or add sprites, sound and music
3. Build and Run cart with nimble:
   ```bash
   nimble runcart
   ```
   or with `build.sh` bash script:
   ```bash
   sh build.sh
   ```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the [MIT License](LICENSE).
