#!/bin/bash
# Fast path: rebuild only x6100_gui from the sibling checkout, using the
# toolchain and libraries already built by a previous full build.
#
# `x6100-gui-rebuild` re-syncs /work/x6100_gui into the build tree (because of
# the OVERRIDE_SRCDIR in build/local.mk), recompiles, and installs into the
# Buildroot target tree. Use docker/gui-package.sh afterwards to produce an
# update archive for the radio.
#
# Note the hyphen: Buildroot names the package after its directory,
# br2_external/package/x6100-gui, so targets are x6100-gui-* while the
# variables are X6100_GUI_*.

source "$(dirname "$0")/common.sh"

require_configured
require_gui_submodules
require_toolchain

grep -q '^X6100_GUI_OVERRIDE_SRCDIR' "$BUILD_DIR/local.mk" 2>/dev/null \
    || cp docker/local.mk "$BUILD_DIR/local.mk"

cap_ccache
make -C "$BUILD_DIR" BR2_JLEVEL="$JOBS" x6100-gui-rebuild

echo
echo "x6100_gui $(gui_version) built and installed into $BUILD_DIR/target"
