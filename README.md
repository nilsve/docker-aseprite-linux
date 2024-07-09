# Docker Aseprite container

This repository allows you to compile Aseprite without installing any build tools. All that is required is Docker.

After spending hours trying to get Aseprite to compile, I decided to just make a Docker image for it 

Currently the script checks out Skia version `m102` and Aseprite version `1.2.40`. You can easily change this in `compile.sh` by changing the `-b` flag to the desired versions.

If any of the folders of the projects folder isn't empty, the script will skip checking out the latest versions. In order to re-download, delete the according folder.
* ./dependencies/depot_tools
* ./dependencies/skia
* ./output/aseprite

## Usage
 * Install docker
 * Clone this repository 
 * cd into cloned repository
 * Run `make build` or `make build-compose` (The latter will use docker-compose to build the image)
 * Grab a cup of coffee, since this can take quite a while (Compiling build deps, skia, and aseprite)

You can now find the compiled version of Aseprite in the `output/aseprite/build/bin` folder

## FAQ
If you get the following error when running Aseprite: `./aseprite: error while loading shared libraries: libdeflate.so.0: cannot open shared object file: No such file or directory`, make sure you have libdeflate installed on your system. Please run
`sudo apt install -y libdeflate0 libdeflate-dev`

If you get the following error: `./aseprite: error while loading shared libraries: libcrypto.so.1.1: cannot open shared object file: No such file or directory`, you'll want to install the OpenSSL 1.1 package/library. You may have only OpenSSL 3.x installed, meanwhile Aseprite still uses the v1.1 library.
* On Arch / Arch based distros, run `sudo pacman -Syu openssl-1.1`
* On Ubuntu try: `sudo apt install -y libssl1.1`

## License

MIT License

Copyright (c) [year] [fullname]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
