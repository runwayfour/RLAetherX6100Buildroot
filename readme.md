# Aether X6100

A project to build a Linux kernel and OS for the Xiegu X6100 without having to
copy files from the vendor's kernel.

## Building

### Building on Linux

To build on a Linux machine, just:

```shell
.\br_config.sh
cd build
make
```

And then you'll have a `sdcard.img` in the `build` directory, you can then
flash.

#### Buildroot dependencies

If you are indeed using Linux, check the pre-requesites of Buildroot
[here](https://buildroot.org/downloads/manual/manual.html#requirement).

### Building with Docker (macOS, or any host with Docker)

Everything runs inside a Ubuntu 22.04 container; the host only needs Docker
(Docker Desktop on macOS, Apple Silicon works natively) and `make`. Build output,
downloads and ccache live in named Docker volumes, so nothing heavy is written
to the bind-mounted checkouts.

Expected layout, as in the x6100_gui README:

```
x6100/
  AetherX6100Buildroot/   this repo
  x6100_gui/              GUI checkout (built from source, not from the pinned tag)
```

```shell
git submodule update --init --recursive          # in both repos
cd AetherX6100Buildroot
make docker-image      # once
make config            # X6100_defconfig + build/local.mk pointing at ../x6100_gui
make image             # full build -> out/sdcard-<ver>.img  (first time: hours, ~20 GB)
```

Day-to-day GUI development:

```shell
make gui               # rebuild only x6100_gui from ../x6100_gui
make package           # -> out/x6100_r1cbu_gui_<ver>.tgz
make deploy RADIO_HOST=192.168.1.50        # copy to the radio's DATA partition and reboot
make deploy-live RADIO_HOST=192.168.1.50   # or: extract over ssh and restart the GUI
```

`make help` lists everything else (`menuconfig`, `savedefconfig`, `shell`,
`br-<any buildroot target>`). The `.devcontainer.json` opens the same container
in VS Code.

Notes:

* Give Docker Desktop plenty of resources: 16 GB RAM and 10+ CPUs are comfortable;
  the virtual disk needs ~20 GB free for the Buildroot output.
* `make image` stamps the prebuilt U-Boot from `x6100_gui/u-boot/` into the image,
  as the upstream release workflow does. Set `USE_PREBUILT_UBOOT=0` to keep the
  U-Boot that Buildroot compiled.
* The update archive only contains files installed by `x6100_gui`. Changes to
  other packages (X6100Control, ft8lib, kernel, ...) need a full `make image`.
* If a package fails to build on an arm64 host, retry with
  `DOCKER_DEFAULT_PLATFORM=linux/amd64 make docker-image` (slow, uses Rosetta).

## Changing buildroot configurations

If you want to change the Buildroot configuration, first do this:

```shell
cd build
make menuconfig
```

### Changing U-Boot and Linux kernel configurations

For those you can just:

```sh
cd build
make uboot-menuconfig
# or
cd build
make linux-menuconfig
```

### Other useful recipes

If you change the `boot.cmd` file, then you have to run:

```sh
make host-uboot-tools-rebuild
make
```

[source](https://stackoverflow.com/questions/66116553/boot-scr-rebuild-in-buildroot)
