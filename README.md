#Docker Aseprite container

This repository allows you to compile Aseprite without installing any build tools. All that is required is Docker.

After spending hours trying to get Aseprite to compile, I decided to just make a Docker image for it 

To simplify and speed up the build process, the build script uses the precompiled version of Skia, which it downloads from the Github repo.

## Usage
 * Install docker
 * Clone this repository 
 * cd into cloned repository
 * Run `docker-compose build`
 * Run `docker-compose up`

You can now find the compiled version of Aseprite in the `output/aseprite/build/bin` folder