# Buildroot package source overrides (copied to build/local.mk by docker/br-config.sh).
#
# With an OVERRIDE_SRCDIR set, Buildroot ignores the git tag pinned in the
# package .mk and instead rsyncs the given directory into the build tree.
# `make <pkg>-rebuild` re-syncs and rebuilds, so edits in the sibling checkout
# are picked up without touching the .mk files.
#
# See https://buildroot.org/downloads/manual/manual.html#_using_buildroot_during_development

X6100_GUI_OVERRIDE_SRCDIR = /work/x6100_gui
X6100_GUI_OVERRIDE_SRCDIR_RSYNC_EXCLUSIONS = \
	--exclude /build --exclude /build_test --exclude /buildroot/build --exclude /.vscode

# To also work on the control library from a local checkout, clone
# https://github.com/gdyuldin/X6100Control next to the other repos, add a bind
# mount for it in docker-compose.yml, and uncomment:
# AETHER_X6100_CONTROL_OVERRIDE_SRCDIR = /work/X6100Control
