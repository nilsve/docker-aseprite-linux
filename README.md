# Docker Aseprite container

This repository allows you to compile Aseprite without installing any build tools. All that is required is Docker.

After spending hours trying to get Aseprite to compile, I decided to just make a Docker image for it.

The script features a comprehensive logging system with robust error handling, and fully configurable build options. By default it compiles Skia version `aseprite-m124` and Aseprite version `v1.3.15.2` with `RelWithDebInfo` build type.

If any of the folders of the projects folder isn't empty, the script will skip checking out the latest versions. In order to re-download, delete the according folder:
* ./dependencies/depot_tools
* ./dependencies/skia
* ./dependencies/aseprite

## Usage

### Quick Start
1. Install docker
2. Clone this repository 
3. cd into cloned repository
4. Run `make build` (uses default settings)
5. Grab a cup of coffee, since this can take quite a while (Compiling build deps, skia, and aseprite)

You can now find the compiled version of Aseprite in the `output/bin` folder (or just `output/aseprite` if bin folder doesn't exist)

### Advanced Usage

The compilation script supports various options that can be passed through the Makefile.

```bash
# Basic usage with default settings
make build

# Using docker-compose (alternative method)
make build-compose

# Pass arguments to the compilation script
make build ARGS="[OPTIONS]"
```

### Available Options

| Command Line Option | Environment Variable | Description |
|---------------------|---------------------|-------------|
| `-a, --aseprite-version VERSION` | `AESCOMPILE_ASEPRITE_VERSION` | Set Aseprite version (default: v1.3.15.2) |
| `-s, --skia-version VERSION` | `AESCOMPILE_SKIA_VERSION` | Set Skia version (default: aseprite-m124) |
| `-d, --dependencies-dir DIR` | `AESCOMPILE_DEPENDENCIES_DIR` | Set dependencies directory (default: /dependencies) |
| `-o, --output-dir DIR` | `AESCOMPILE_OUTPUT_DIR` | Set output directory (default: /output) |
| `-b, --build-type TYPE` | `AESCOMPILE_BUILD_TYPE` | CMake build type: `Release` or `RelWithDebInfo` (default: RelWithDebInfo) |
| `-v, --verbose` | `AESCOMPILE_VERBOSITY` | Increase verbosity (0=critical, 1=error, 2=warning, 3=info, 4=debug) |
| `-q, --quiet` | `AESCOMPILE_QUIET` | Suppress output except errors and critical messages |
| `-n, --no-color` | `AESCOMPILE_NO_COLOR` | Disable colored output and emojis |
| `-h, --help` | N/A | Display help message and exit |

### Examples

```bash
# Basic compilation with default settings
make build

# Compile specific versions with verbose output
make build ARGS="-a v1.3.15.2 -s aseprite-m124 -v"

# Compile older versions
make build ARGS="--aseprite-version v1.3.10 --skia-version aseprite-m102"

# Use custom directories (mapped to host paths via Docker volumes)
make build ARGS="-d /custom/deps -o /custom/output"

# Release build without debug info, no colors/emojis, quiet mode
make build ARGS="-b Release --no-color --quiet"

# Maximum verbosity for debugging (shows debug, info, warning, error, critical)
make build ARGS="-vvvv"

# Debug mode with real-time output processing
make build ARGS="-vvv --no-color"  # Clean debug output without colors

# Show comprehensive help with all options
make build ARGS="--help"
```

### Build Types

- **RelWithDebInfo** (default): Optimized build with debug information included
* **Release**: Fully optimized build without debug information (smaller binary)

## FAQ

If you get the following error when running Aseprite: `./aseprite: error while loading shared libraries: libdeflate.so.0: cannot open shared object file: No such file or directory`, make sure you have libdeflate installed on your system. Please run
`sudo apt install -y libdeflate0 libdeflate-dev`

If you get the following error: `./aseprite: error while loading shared libraries: libcrypto.so.1.1: cannot open shared object file: No such file or directory`, you'll want to install the OpenSSL 1.1 package/library. You may have only OpenSSL 3.x installed, meanwhile Aseprite still uses the v1.1 library.

* On Arch / Arch based distros, run `sudo pacman -Syu openssl-1.1`
* On Ubuntu try: `sudo apt install -y libssl1.1`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.