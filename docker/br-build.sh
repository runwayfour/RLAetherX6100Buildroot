#!/bin/bash
# Full Buildroot build: toolchain, kernel, U-Boot, rootfs and sdcard.img.
# Mirrors the steps of the upstream GitHub Actions workflow in x6100_gui.
#
# Output: out/sdcard-<gui version>.img (+ .zip)
#
# Environment:
#   JOBS                parallel jobs (default: nproc)
#   CCACHE_SIZE         ccache limit (default: 8G)
#   USE_PREBUILT_UBOOT  1 (default) stamps x6100_gui/u-boot/u-boot-sunxi-with-spl.bin
#                       into the image like upstream releases do; 0 keeps the
#                       U-Boot that Buildroot compiled.

source "$(dirname "$0")/common.sh"

require_buildroot_submodule
require_gui_submodules
[ -f "$BUILD_DIR/.config" ] || docker/br-config.sh

BR="make -C $BUILD_DIR BR2_JLEVEL=$JOBS"

$BR host-ccache
cap_ccache

# Upstream CI builds these two first and then forces libsndfile to reconfigure,
# otherwise libsndfile gets configured without mp3 support. Keep the same order.
$BR lame mpg123 libsndfile-dirclean
$BR

IMG=$BUILD_DIR/images/sdcard.img
[ -f "$IMG" ] || die "build finished but $IMG was not produced"

UBOOT=$GUI_SRC/u-boot/u-boot-sunxi-with-spl.bin
if [ "${USE_PREBUILT_UBOOT:-1}" = "1" ] && [ -f "$UBOOT" ]; then
    echo "Stamping prebuilt U-Boot from x6100_gui into the image (offset 8K)"
    dd if="$UBOOT" of="$IMG" bs=1024 seek=8 conv=notrunc status=none
fi

VER=$(gui_version)
mkdir -p "$OUT_DIR"
cp "$IMG" "$OUT_DIR/sdcard-$VER.img"
(cd "$OUT_DIR" && rm -f "sdcard-$VER.img.zip" && zip -q "sdcard-$VER.img.zip" "sdcard-$VER.img")

echo
echo "Image ready:"
ls -lh "$OUT_DIR/sdcard-$VER.img" "$OUT_DIR/sdcard-$VER.img.zip"
