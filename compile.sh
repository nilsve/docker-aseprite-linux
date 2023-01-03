#!/bin/bash

# Fail on errors
set -e

echo "Download and compile Skia & other dependencies"
cd /dependencies

if [ ! -d "/dependencies/depot_tools" ]
then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

if [ ! -d "/dependencies/skia" ]
then
  git clone -b aseprite-m102 https://github.com/aseprite/skia.git
fi

export PATH="${PWD}/depot_tools:${PATH}"

cd skia
pwd
echo "Syncing skia dependencies"
python3 tools/git-sync-deps

echo "Compiling skia"
gn gen out/Release-x64 --args="is_debug=false is_official_build=true skia_use_system_expat=false skia_use_system_icu=false skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_sfntly=false skia_use_freetype=true skia_use_harfbuzz=true skia_pdf_subset_harfbuzz=true skia_use_system_freetype2=false skia_use_system_harfbuzz=false"
ninja -C out/Release-x64 skia modules

echo "Download Aseprite and compile"
cd /output

if [ ! -d "/output/aseprite" ]
then
  git clone -b v1.2.40 --recursive https://github.com/aseprite/aseprite.git
fi

cd aseprite
mkdir -p build
cd build

echo "Compiling Asperite"
cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR=/dependencies/skia \
  -DSKIA_LIBRARY_DIR=/dependencies/skia/out/Release-x64 \
  -DSKIA_LIBRARY=/dependencies/skia/out/Release-x64/libskia.a \
  -G Ninja \
  ..

echo "Linking Aseprite"
ninja aseprite
