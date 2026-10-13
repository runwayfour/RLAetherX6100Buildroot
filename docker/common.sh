# Shared setup for the docker/*.sh helper scripts (sourced, not executed).

set -euo pipefail

BR_ROOT=/work/AetherX6100Buildroot
GUI_SRC=/work/x6100_gui
BUILD_DIR=$BR_ROOT/build
OUT_DIR=$BR_ROOT/out
JOBS=${JOBS:-$(nproc)}

cd "$BR_ROOT"

die() { echo "error: $*" >&2; exit 1; }

require_buildroot_submodule() {
    [ -f buildroot/Makefile ] || die "buildroot/ submodule is empty; run on the host: git submodule update --init --recursive"
}

require_configured() {
    [ -f "$BUILD_DIR/.config" ] || die "Buildroot is not configured yet; run: make config"
}

require_gui_submodules() {
    [ -f "$GUI_SRC/CMakeLists.txt" ] || die "x6100_gui not found at $GUI_SRC (set X6100_GUI_DIR on the host)"
    [ -f "$GUI_SRC/lvgl/CMakeLists.txt" ] || die "x6100_gui/lvgl submodule is empty; run in x6100_gui: git submodule update --init --recursive"
}

require_toolchain() {
    [ -f "$BUILD_DIR/host/share/buildroot/toolchainfile.cmake" ] \
        || die "the cross toolchain has not been built yet; run 'make image' once (this takes a while)"
}

# Version string used to name output files, taken from the GUI checkout.
gui_version() {
    git -C "$GUI_SRC" describe --tags --always --dirty 2>/dev/null || echo "local"
}

# Keep ccache bounded (the defconfig's initial setup asks for 32G).
cap_ccache() {
    if [ -x "$BUILD_DIR/host/bin/ccache" ]; then
        "$BUILD_DIR/host/bin/ccache" -M "${CCACHE_SIZE:-8G}" >/dev/null || true
    fi
}
