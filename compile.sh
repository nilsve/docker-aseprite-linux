#!/bin/bash

# Download Skia
if [ ! -d "/dependencies/skia" ]
then
  curl -L https://github.com/aseprite/skia/releases/download/m81-b607b32047/Skia-Linux-Release-x64.zip --output /dependencies/skia.zip
  unzip /dependencies/skia.zip -d /dependencies/skia
fi

git clone --recursive https://github.com/aseprite/aseprite.git
cd aseprite
mkdir -p build
cd build
cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR=/dependencies/skia \
  -DSKIA_LIBRARY_DIR=/dependencies/skia/out/Release-x64 \
  -DSKIA_LIBRARY=/dependencies/skia/out/Release-x64/libskia.a \
  -G Ninja \
  ..
ninja aseprite