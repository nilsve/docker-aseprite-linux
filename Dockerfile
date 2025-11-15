FROM python:3.12-slim-trixie

ARG TZ=America/Los_Angeles
ARG LANG=C.UTF-8
ARG AESCOMPILE_ASEPRITE_VERSION=v1.3.15.2
ARG AESCOMPILE_SKIA_VERSION=aseprite-m124
ARG AESCOMPILE_DEPENDENCIES_DIR=/dependencies
ARG AESCOMPILE_OUTPUT_DIR=/output
ARG AESCOMPILE_BUILD_TYPE=RelWithDebInfo
ARG AESCOMPILE_VERBOSITY=3
ARG AESCOMPILE_NO_COLOR=false
ARG AESCOMPILE_QUIET=false

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=${LANG}
ENV LC_ALL=${LANG}
ENV TZ=${TZ}
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_ROOT_USER_ACTION=ignore
ENV AESCOMPILE_ASEPRITE_VERSION=${AESCOMPILE_ASEPRITE_VERSION:-v1.3.15.2}
ENV AESCOMPILE_SKIA_VERSION=${AESCOMPILE_SKIA_VERSION:-aseprite-m124}
ENV AESCOMPILE_DEPENDENCIES_DIR=${AESCOMPILE_DEPENDENCIES_DIR:-/dependencies}
ENV AESCOMPILE_OUTPUT_DIR=${AESCOMPILE_OUTPUT_DIR:-/output}
ENV AESCOMPILE_BUILD_TYPE=${AESCOMPILE_BUILD_TYPE:-RelWithDebInfo}
ENV AESCOMPILE_VERBOSITY=${AESCOMPILE_VERBOSITY:-3}
ENV AESCOMPILE_NO_COLOR=${AESCOMPILE_NO_COLOR:-false}
ENV AESCOMPILE_QUIET=${AESCOMPILE_QUIET:-false}

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    git \
    unzip \
    curl \
    build-essential \
    g++ \
    clang \
    cmake \
    ninja-build \
    libx11-dev \
    libxcursor-dev \
    libxi-dev \
    libxrandr-dev \
    libgl1-mesa-dev \
    libfontconfig1-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY compile.sh /

VOLUME /dependencies
VOLUME /output

WORKDIR /output

RUN ["chmod", "+x", "/compile.sh"]

ENTRYPOINT ["/compile.sh"]
