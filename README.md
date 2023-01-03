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
 * Run `docker-compose build`
 * Run `docker-compose up`
 * Grab a cup of coffee, since this can take quite a while (Compiling build deps, skia, and aseprite)

You can now find the compiled version of Aseprite in the `output/aseprite/build/bin` folder

## FAQ
If you get the following error when running Aseprite: `./aseprite: error while loading shared libraries: libdeflate.so.0: cannot open shared object file: No such file or directory`, make sure you have libdeflate installed on your system. Please run
`sudo apt install -y libdeflate0 libdeflate-dev`
