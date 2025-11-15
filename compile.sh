#!/usr/bin/env bash
set -euo pipefail

AESCOMPILE_ASEPRITE_VERSION=${AESCOMPILE_ASEPRITE_VERSION:-v1.3.15.2}
AESCOMPILE_SKIA_VERSION=${AESCOMPILE_SKIA_VERSION:-aseprite-m124}
AESCOMPILE_DEPENDENCIES_DIR=${AESCOMPILE_DEPENDENCIES_DIR:-/dependencies}
AESCOMPILE_OUTPUT_DIR=${AESCOMPILE_OUTPUT_DIR:-/output}
AESCOMPILE_BUILD_TYPE=${AESCOMPILE_BUILD_TYPE:-RelWithDebInfo}
AESCOMPILE_VERBOSITY=${AESCOMPILE_VERBOSITY:-3}
AESCOMPILE_NO_COLOR=${AESCOMPILE_NO_COLOR:-false}
AESCOMPILE_QUIET=${AESCOMPILE_QUIET:-false}

AESCOMPILE_ORIGINAL_PATH="$PATH"
C_RED=$(tput setaf 1); C_GREEN=$(tput setaf 2); C_YELLOW=$(tput setaf 3); C_MAGENTA=$(tput setaf 5); C_CYAN=$(tput setaf 6); C_BOLD=$(tput bold); C_RESET=$(tput sgr0)
declare -A LOG_CONFIG=(["debug"]="0:$C_CYAN:🔍" ["info"]="1:$C_GREEN:ℹ️" ["warning"]="2:$C_YELLOW:⚠️" ["error"]="3:$C_RED:❌" ["critical"]="4:$C_MAGENTA:🚨")

__log() {
    local l m c n t r u e
    l="$1"; shift; m="$*"; c="${LOG_CONFIG[$l]}"
    [[ -z "$c" ]] && return 1
    n="${c%%:*}"; r="${c#*:}"; r="${r%%:*}"; e="${c##*:}"
    [[ $n -lt $((4 - AESCOMPILE_VERBOSITY)) ]] && return 0
    [[ "$AESCOMPILE_QUIET" == "true" && "$l" != "error" && "$l" != "critical" ]] && return 0
    t=$(date '+%Y-%m-%d %H:%M:%S'); c=""
    u=$(echo "$l" | tr '[:lower:]' '[:upper:]')
    if [[ "$AESCOMPILE_NO_COLOR" == "false" ]]; then 
        c="$C_RESET"
        printf "%s[%s] %s%s  %-8s%s %s\n" "$r" "$t" "$r" "$e" "$u" "$c" "$m"
    else 
        r=""
        printf "[%s] %-8s %s\n" "$t" "$u" "$m"
    fi
}

__add_path() {
    local p="$1"
    [[ -z "$p" || ! -d "$p" ]] && return 1
    [[ ":$PATH:" != *":$p:"* ]] && PATH="$p:$PATH"
    __log "debug" "Added to PATH: $p"
}

__rm_path() {
    local p="$1" n
    [[ -z "$p" ]] && return 1
    n=$(echo ":$PATH:" | sed "s|:$p:|:|g" | sed 's/^://;s/:$//')
    [[ "$PATH" != "$n" ]] && { PATH="$n"; __log "debug" "Removed from PATH: $p"; }
}

__find_openssl() {
    local d dirs=("/usr" "/usr/local" "/opt/homebrew" "/usr/local/opt/openssl@1.1" "/usr/local/opt/openssl@3" "/usr/local/ssl")
    for d in "${dirs[@]}"; do
        if [[ -f "$d/include/openssl/opensslv.h" && (-f "$d/lib/libssl.so" || -f "$d/lib/libssl.a" || -f "$d/lib/libssl.dylib") ]]; then
            __log "debug" "Found OpenSSL at: $d"
            echo "$d"
            return 0
        fi
    done
    __log "warning" "OpenSSL not found in standard locations"
    return 1
}

__strip_line() {
    local line="$1"
    line=$(echo "$line" | sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' | sed 's/\x1b\[[0-9]*m//g' | tr -cd '[:print:][:space:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    echo "$line"
}

__process_output() {
    local f
    f="$1"
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local l m
            l=$(__strip_line "$line")
            m=$(echo "$l" | tr '[:upper:]' '[:lower:]')
            if [[ "$m" == *"error:"* || "$m" == *"err:"* || "$m" == *"fatal:"* || "$m" == *"failed:"* || "$m" == *"fail:"* ]]; then
                __log "error" "$l"
            elif [[ "$m" == *"warning:"* || "$m" == *"warn:"* ]]; then
                __log "warning" "$l"
            else
                __log "debug" "$l"
            fi
        fi
    done < "$f"
}

__cmd() {
    local c o e p q x
    c="$*"; o="/tmp/cmd_stdout_$$"; e="/tmp/cmd_stderr_$$"
    __log "debug" "Executing command: $c"
    mkfifo "$o" "$e"
    __process_output "$o" &
    p=$!
    __process_output "$e" &
    q=$!
    eval "$c" > "$o" 2> "$e"
    x=$?
    wait $p $q
    rm -f "$o" "$e"
    return $x
}

__cleanup() {
    local e r s f
    e=$?; r="${1:-normal}"; s="/tmp/compile_stderr_$$"; f=("$s" "/tmp/compile_*.$$" "/tmp/cmd_stdout_$$" "/tmp/cmd_stderr_$$")
    [[ "$PATH" != "$AESCOMPILE_ORIGINAL_PATH" ]] && { PATH="$AESCOMPILE_ORIGINAL_PATH"; __log "debug" "Restored original PATH"; }
    for p in "${f[@]}"; do rm -f $p 2>/dev/null || true; done
    case "$r" in
        "error") __log "debug" "Cleanup completed after error (exit code: $e)" ;;
        "interrupt") __log "warning" "Script interrupted by user, cleaning up..." ;;
        "normal") if [[ $e -eq 0 ]]; then __log "debug" "Script completed successfully, cleaning up..."; else __log "warning" "Script completed with non-zero exit code ($e), cleaning up..."; fi ;;
    esac
    return $e
}

__error() {
    local e l c s x m f
    e=$?; l=$1; c=$3; s=("${FUNCNAME[@]:-}")
    [[ $e -eq 0 ]] && e=1
    x=""; [[ ${#s[@]} -gt 1 ]] && x=" in function ${s[1]}()"
    m=""; f="/tmp/compile_stderr_$$"
    [[ -f "$f" ]] && m=$(tail -n 1 "$f" 2>/dev/null | sed 's/^.*: //')
    __log "critical" "Script failed at line ${l}${x}"
    __log "critical" "Command: ${c}"
    [[ -n "$m" ]] && __log "critical" "Error: ${m}"
    __log "critical" "Exit code: ${e}"
    if [[ ${#s[@]} -gt 2 ]]; then
        __log "critical" "Call stack:"; local i; for ((i=1; i<${#s[@]}; i++)); do __log "critical" "  $((i-1)): ${s[i]}()"; done
    fi
    trap - EXIT; __cleanup "error"; exit $e
}

__interrupt() {
    local e
    e=130
    __log "warning" "Script interrupted by user (Ctrl+C)"
    trap - EXIT; __cleanup "interrupt"
    exit $e
}

__usage() {
    local b r
    if [[ "$AESCOMPILE_NO_COLOR" != "true" ]]; then b="$C_BOLD"; r="$C_RESET"; fi
  cat << EOF
${b}Usage:${r} $(basename "$0") [OPTIONS]
${b}Description:${r}
Compile Aseprite with Skia dependencies.
${b}Options:${r}
  ${b}-a, --aseprite-version${r} VERSION    Set Aseprite version (default: v1.3.15.2)
  ${b}-s, --skia-version${r} VERSION        Set Skia version (default: aseprite-m124)
  ${b}-d, --dependencies-dir${r} DIR        Set dependencies directory (default: /dependencies)
  ${b}-o, --output-dir${r} DIR              Set output directory (default: /output)
  ${b}-b, --build-type${r} TYPE             Set CMake build type: Release or RelWithDebInfo (default: RelWithDebInfo)
  ${b}-v, --verbose${r}                     Increase verbosity level (can be used multiple times)
                                    Levels: 0=critical, 1=error, 2=warning, 3=info, 4=debug
  ${b}-q, --quiet${r}                       Suppress all output except errors and critical messages
  ${b}-n, --no-color${r}                    Disable colored output
  ${b}-h, --help${r}                        Display this help message
${b}Examples:${r}
  $(basename "$0") -a v1.3.15.2 -s aseprite-m124
  $(basename "$0") --aseprite-version v1.3.10 --skia-version aseprite-m102
  $(basename "$0") -d /custom/deps -o /custom/output
  $(basename "$0") -b Release --no-color    # Release build without colors
  $(basename "$0") -vv --no-color   # Very verbose without colors
  $(basename "$0") -q               # Quiet mode
EOF
}

__parse() {
    local -a a=("$@"); for (( i=0; i<${#a[@]}; )); do
        case ${a[i]} in
            -a|--aseprite-version) AESCOMPILE_ASEPRITE_VERSION="${a[i+1]}"; i=$((i+2)) ;;
            -s|--skia-version) AESCOMPILE_SKIA_VERSION="${a[i+1]}"; i=$((i+2)) ;;
            -d|--dependencies-dir) AESCOMPILE_DEPENDENCIES_DIR="${a[i+1]}"; i=$((i+2)) ;;
            -o|--output-dir) AESCOMPILE_OUTPUT_DIR="${a[i+1]}"; i=$((i+2)) ;;
            -b|--build-type) AESCOMPILE_BUILD_TYPE="${a[i+1]}"; i=$((i+2)) ;;
            -v|--verbose) ((AESCOMPILE_VERBOSITY++)); [[ $AESCOMPILE_VERBOSITY -gt 4 ]] && AESCOMPILE_VERBOSITY=4; i=$((i+1)) ;;
            -q|--quiet) AESCOMPILE_QUIET=true; i=$((i+1)) ;;
            -n|--no-color) AESCOMPILE_NO_COLOR=true; i=$((i+1)) ;;
            -h|--help) __usage; exit 0 ;;
            *) __log "error" "Unknown option: ${a[i]}"; __usage; exit 1 ;;
        esac
    done
}

exec 2> >(tee "/tmp/compile_stderr_$$" >/dev/null)
trap '__error ${LINENO} ${BASH_LINENO} "$BASH_COMMAND"' ERR
trap '__interrupt' INT TERM
trap '__cleanup "normal"' EXIT

# Main() ########################
[[ ! "${BASH_SOURCE[0]}" == "${0}" ]] && return 0
__parse "$@"
__log "info" "Building Aseprite version: ${AESCOMPILE_ASEPRITE_VERSION} (${AESCOMPILE_BUILD_TYPE})"
__log "info" "Using Skia version: ${AESCOMPILE_SKIA_VERSION}"

cd "${AESCOMPILE_DEPENDENCIES_DIR}"
if [ ! -d "${AESCOMPILE_DEPENDENCIES_DIR}/depot_tools" ]; then
    __log "info" "Cloning depot_tools"
    __cmd git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    cd depot_tools
    __cmd git checkout main
    cd ..
else
    cd depot_tools
    __log "info" "Checking out latest depot_tools"
    __cmd git checkout main
    __cmd git pull
    cd ..
fi
__add_path "${PWD}/depot_tools"
__cmd gclient
if [ ! -d "${AESCOMPILE_DEPENDENCIES_DIR}/skia" ]; then
    __log "info" "Cloning skia"
    __cmd git clone -b "${AESCOMPILE_SKIA_VERSION}" https://github.com/aseprite/skia.git
else
    __log "info" "Updating to latest Skia version"
    cd skia
    __cmd git fetch
    __cmd git checkout "${AESCOMPILE_SKIA_VERSION}"
    cd ..
fi
cd skia
__log "debug" "Current directory: $(pwd)"
__log "info" "Syncing skia dependencies"
__cmd python3 tools/git-sync-deps
__log "info" "Compiling skia"
__cmd gn gen out/Release-x64 --args=\"is_debug=false is_official_build=true skia_use_system_expat=false skia_use_system_icu=false skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_freetype=true skia_use_harfbuzz=true skia_pdf_subset_harfbuzz=true skia_use_system_freetype2=false skia_use_system_harfbuzz=false\"
__cmd ninja -C out/Release-x64 skia modules
cd "${AESCOMPILE_DEPENDENCIES_DIR}"
if [ ! -d "${AESCOMPILE_DEPENDENCIES_DIR}/aseprite" ]; then
    __log "info" "Cloning Aseprite"
    __cmd git clone -b "${AESCOMPILE_ASEPRITE_VERSION}" --recursive https://github.com/aseprite/aseprite.git
else
    __log "info" "Updating to latest Aseprite version"
    cd aseprite
    __cmd git fetch
    __cmd git switch "${AESCOMPILE_ASEPRITE_VERSION}" --detach
    cd ..
fi
cd aseprite
mkdir -p build
cd build
__log "info" "Compiling Aseprite"
OPENSSL_ROOT=$(__find_openssl) || OPENSSL_ROOT=""
CMAKE_ARGS="-DCMAKE_BUILD_TYPE=${AESCOMPILE_BUILD_TYPE} -DLAF_BACKEND=skia -DSKIA_DIR=${AESCOMPILE_DEPENDENCIES_DIR}/skia -DSKIA_LIBRARY_DIR=${AESCOMPILE_DEPENDENCIES_DIR}/skia/out/Release-x64 -DSKIA_LIBRARY=${AESCOMPILE_DEPENDENCIES_DIR}/skia/out/Release-x64/libskia.a -G Ninja"
[[ -n "$OPENSSL_ROOT" ]] && CMAKE_ARGS="$CMAKE_ARGS -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT"
__cmd cmake $CMAKE_ARGS ..
__log "info" "Linking Aseprite"
__cmd ninja aseprite
__log "info" "Copying build results to output directory"
mkdir -p "${AESCOMPILE_OUTPUT_DIR}"
cp -r bin "${AESCOMPILE_OUTPUT_DIR}/" 2>/dev/null || cp aseprite "${AESCOMPILE_OUTPUT_DIR}/" 2>/dev/null || __log "warning" "Could not copy build results"
__log "info" "Compilation completed successfully!"