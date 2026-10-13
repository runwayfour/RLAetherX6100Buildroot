# Host-side entry point: every build step runs inside the Docker image defined
# by Dockerfile / docker-compose.yml. Works on macOS (Apple Silicon or Intel)
# and Linux. Run `make help` for the list of targets.
#
# Expected layout (same as the x6100_gui README):
#   x6100/
#     AetherX6100Buildroot/   this repo
#     x6100_gui/              GUI checkout, built from source (override X6100_GUI_DIR)

COMPOSE   ?= docker compose
RUN        = $(COMPOSE) run --rm buildroot
RADIO_HOST ?=
RADIO_USER ?= root

.DEFAULT_GOAL := help
.PHONY: help docker-image shell config image gui package deploy deploy-live \
        menuconfig savedefconfig clean-gui distclean

help:
	@echo "Docker-based X6100 build. Targets:"
	@echo
	@echo "  make docker-image   build/refresh the Docker image (once, and after Dockerfile changes)"
	@echo "  make config         configure Buildroot (X6100_defconfig) + local source overrides"
	@echo "  make image          full build -> out/sdcard-<ver>.img   (first run: 1-3 h, ~20 GB)"
	@echo "  make gui            rebuild only x6100_gui from ../x6100_gui (fast, needs a prior 'image')"
	@echo "  make package        out/x6100_r1cbu_gui_<ver>.tgz update archive for the radio"
	@echo "  make deploy         copy that archive to the radio's DATA partition and reboot it"
	@echo "  make deploy-live    extract the archive over ssh and restart the GUI, no reboot"
	@echo "  make shell          interactive shell in the build container"
	@echo "  make menuconfig     Buildroot menuconfig (also: make br-linux-menuconfig, br-uboot-menuconfig)"
	@echo "  make savedefconfig  write the current .config back to br2_external/configs/X6100_defconfig"
	@echo "  make br-<target>    run any Buildroot make target, e.g. make br-x6100-gui-dirclean"
	@echo "  make clean-gui      remove the x6100_gui build tree (next 'make gui' starts clean)"
	@echo "  make distclean      delete the build, download and ccache volumes"
	@echo
	@echo "Variables: JOBS=<n>  CCACHE_SIZE=8G  USE_PREBUILT_UBOOT=1  X6100_GUI_DIR=../x6100_gui"
	@echo "           RADIO_HOST=<ip or hostname>  RADIO_USER=root  DEFCONFIG=X6100_defconfig"

docker-image:
	$(COMPOSE) build

shell:
	$(RUN) bash

config:
	$(RUN) docker/br-config.sh $(DEFCONFIG)

image:
	$(RUN) docker/br-build.sh

gui:
	$(RUN) docker/gui-build.sh

package:
	$(RUN) docker/gui-package.sh

menuconfig:
	$(RUN) make -C build menuconfig

savedefconfig:
	$(RUN) make -C build savedefconfig BR2_DEFCONFIG=../br2_external/configs/$(or $(DEFCONFIG),X6100_defconfig)

br-%:
	$(RUN) make -C build $*

clean-gui:
	$(RUN) make -C build x6100-gui-dirclean

distclean:
	$(COMPOSE) down --volumes --remove-orphans

# --- Deploy to the radio (runs on the host, needs ssh/scp and the radio on the network) ---

LATEST_PKG = $(lastword $(sort $(wildcard out/x6100_r1cbu_gui_*.tgz)))

define need_radio
	@test -n "$(RADIO_HOST)" || { echo "set RADIO_HOST=<radio ip/hostname> (root password on the stock image is 123)"; exit 1; }
	@test -n "$(LATEST_PKG)" || { echo "no out/x6100_r1cbu_gui_*.tgz found; run 'make package' first"; exit 1; }
endef

# The radio's S02update script applies /mnt/x6100_r1cbu_*.tgz on boot, keeping a
# backup of the replaced files as /mnt/backup_<name>.tgz.
deploy:
	$(need_radio)
	scp "$(LATEST_PKG)" $(RADIO_USER)@$(RADIO_HOST):/mnt/
	ssh $(RADIO_USER)@$(RADIO_HOST) 'sync; reboot'
	@echo "Copied $(notdir $(LATEST_PKG)) to $(RADIO_HOST):/mnt and rebooted; the update applies during boot."

# Same files, applied immediately without a reboot or backup.
deploy-live:
	$(need_radio)
	ssh $(RADIO_USER)@$(RADIO_HOST) '/etc/init.d/S95gui stop; cd / && tar -xzf - && sync && /etc/init.d/S95gui start' < "$(LATEST_PKG)"
	@echo "Deployed $(notdir $(LATEST_PKG)) to $(RADIO_HOST) and restarted the GUI."
