#!/bin/bash
# Configure Buildroot (equivalent of ./br_config.sh) and install the package
# source overrides so x6100_gui is built from the sibling checkout.
#
# Usage: docker/br-config.sh [defconfig]   (default: X6100_defconfig)

source "$(dirname "$0")/common.sh"

DEFCONFIG=${1:-${DEFCONFIG:-X6100_defconfig}}

require_buildroot_submodule

make -C buildroot BR2_EXTERNAL=../br2_external O=../build "$DEFCONFIG"
cp docker/local.mk "$BUILD_DIR/local.mk"

echo
echo "Configured $DEFCONFIG in $BUILD_DIR"
echo "x6100_gui will be built from $GUI_SRC (see $BUILD_DIR/local.mk)"
