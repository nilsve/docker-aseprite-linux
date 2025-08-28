#!/bin/bash

# Fail on errors
set -e

ASEPRITE_VERSION=v1.3.15.2
SKIA_VERSION=aseprite-m124

echo "Download and compile Skia & other dependencies"
cd /dependencies

if [ ! -d "/dependencies/depot_tools" ]
then
  echo "Cloning depot_tools"
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  git checkout main
else
  cd depot_tools
  echo "Checking out latest depot_tools"
  git checkout main
  git pull
  cd ..
fi

export PATH="${PWD}/depot_tools:${PATH}"
gclient

if [ ! -d "/dependencies/skia" ]
then
  echo "Cloning skia"
  git clone -b "${SKIA_VERSION}" https://github.com/aseprite/skia.git
else
  echo "Updating to latest Skia version"
  cd skia
  git fetch
  git checkout "${SKIA_VERSION}"
  cd ..
fi

cd skia
pwd
echo "Syncing skia dependencies"
python3 tools/git-sync-deps

echo "Compiling skia"
gn gen out/Release-x64 --args="is_debug=false is_official_build=true skia_use_system_expat=false skia_use_system_icu=false skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_sfntly=false skia_use_freetype=true skia_use_harfbuzz=true skia_pdf_subset_harfbuzz=true skia_use_system_freetype2=false skia_use_system_harfbuzz=false"
ninja -C out/Release-x64 skia modules

cd /output

if [ ! -d "/output/aseprite" ]
then
  echo "Cloning Aseprite"
  git clone -b "${ASEPRITE_VERSION}" --recursive https://github.com/aseprite/aseprite.git
else
  echo "Updating to latest Aseprite version"
  cd aseprite
  git fetch
  git switch "${ASEPRITE_VERSION}" --detach
  cd ..
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
