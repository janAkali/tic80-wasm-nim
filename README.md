# TIC80-WASM-Nim

**TIC80-WASM-Nim** is a template for building TIC-80 WASM carts using the Nim programming language.

## Getting Started

Follow the steps below to set up the project:

### Prerequisites

- [WASI-SDK](https://github.com/WebAssembly/wasi-sdk) installed anywhere on your system
- [TIC-80](https://tic80.com/) added to your system's `PATH`
- [Nim](https://nim-lang.org/) compiler (version 2.0.0 or higher)

### Installation

1. Clone the repository:
   ```bash
   git clone https://codeberg.org/janakali/tic80-wasm-nim
   cd tic80-wasm-nim
   ```

2. Set the `WASI_SDK_PATH` environment variable to point to your WASI-SDK installation:
   ```bash
   export WASI_SDK_PATH=/path/to/wasi-sdk
   ```

3. Verify that `tic80` is available in your `PATH`:
   ```bash
   tic80 --version
   ```

## Building and Running

This template provides two ways to build and run your project:

### Method 1: Using Nimble Tasks (Recommended)

The main way to build and run your project is through nimble tasks defined in `cart.nimble`:

- **Build and run the cartridge**:
  ```bash
  nimble runcart
  ```

- **Build only (without running)**:
  ```bash
  nimble buildcart
  ```

- **Edit the base cartridge** (to modify sprites, sounds, or music):
  ```bash
  nimble editcart
  ```

### Method 2: Using Build Script

Alternatively, you can use the `build.sh` script if you prefer not to use nimble tasks. The script accepts an optional directory path as an argument:

- **Build and run main project**:
  ```bash
  sh build.sh
  ```

- **Or specify a project/demo directory**:
  ```bash
  # Build and run main project
  sh build.sh src

  # Build and run blockgame demo
  sh build.sh demo/blockgame
  ```

The build script compiles the Nim code to WebAssembly, imports it into the TIC-80 cartridge, and automatically runs the result.

## Demo Projects

The template includes two demo projects in the `demo/` directory:
- `blockgame/` - A simple tetris clone example
- `bunnymark/` - A performance testing demo

To run a demo:
```bash
sh build.sh demo/blockgame
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue on Codeberg.

## License

This project is licensed under the [MIT License](LICENSE).
