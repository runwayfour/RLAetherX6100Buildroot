#!/bin/bash
# Package the built x6100_gui as an update archive the radio applies itself.
#
# The stock firmware's /etc/init.d/S02update looks for /mnt/x6100_r1cbu_*.tgz on
# the DATA partition at boot, backs up the files it is about to replace, extracts
# the archive over /, and deletes it. So an archive containing exactly the files
# x6100_gui installs (binary, daemon, init script, images, cty.dat, sql) is a
# complete GUI update. Libraries from other Buildroot packages (X6100Control,
# ft8lib, rhvoice, ...) are NOT included; changes to those need a full image.
#
# Output: out/x6100_r1cbu_gui_<gui version>.tgz
#
# The archive lists plain files only (no directory entries and no "./" prefix),
# because S02update's backup step feeds `tar -tf` output back into `tar -cf`;
# a "./" entry there would make it archive the whole root filesystem.

source "$(dirname "$0")/common.sh"

require_configured
require_toolchain

# Ask Buildroot where it built the package (build/build/x6100-gui-custom when
# the local override is active).
PKG_BUILD=$(make -C "$BUILD_DIR" -s printvars VARS=X6100_GUI_BUILDDIR | sed -n 's/^X6100_GUI_BUILDDIR=//p')
[ -n "$PKG_BUILD" ] || die "could not determine X6100_GUI_BUILDDIR from Buildroot"
[ -f "$PKG_BUILD/Makefile" ] || die "x6100_gui has not been built yet (no CMake tree in $PKG_BUILD); run: make gui"
[ -f "$PKG_BUILD/.stamp_target_installed" ] || [ -f "$(dirname "$PKG_BUILD")/.stamp_target_installed" ] \
    || echo "warning: x6100_gui is not marked installed by Buildroot; packaging whatever is in $PKG_BUILD"

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

export PATH=$BUILD_DIR/host/bin:$PATH
make -C "$PKG_BUILD" DESTDIR="$STAGE" install >/dev/null

# Strip like Buildroot's target-finalize does; the install step leaves symbols in.
STRIP=$(ls "$BUILD_DIR"/host/bin/arm-*-strip 2>/dev/null | head -n1 || true)
if [ -n "$STRIP" ]; then
    find "$STAGE" -type f -exec sh -c 'file -b "$1" | grep -q "ELF .*ARM" && "$0" --strip-unneeded "$1"' "$STRIP" {} \; 2>/dev/null || true
fi

VER=$(gui_version)
NAME=x6100_r1cbu_gui_${VER}.tgz
mkdir -p "$OUT_DIR"
(cd "$STAGE" && find . \( -type f -o -type l \) | sed 's,^\./,,' | sort \
    | tar -czf "$OUT_DIR/$NAME" --owner=0 --group=0 --no-recursion -T -)

echo
echo "Update archive: out/$NAME"
tar -tzf "$OUT_DIR/$NAME" | sed 's/^/  /' | head -n 20
COUNT=$(tar -tzf "$OUT_DIR/$NAME" | wc -l)
[ "$COUNT" -gt 20 ] && echo "  ... ($COUNT files total)"
ls -lh "$OUT_DIR/$NAME"
