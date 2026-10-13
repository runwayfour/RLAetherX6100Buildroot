# Build environment for AetherX6100Buildroot + x6100_gui.
#
# Ubuntu 22.04 matches the upstream GitHub Actions runner (ubuntu-22.04), which is
# the host Buildroot 2022.11 is known to build on. Newer Ubuntu releases drop
# libncurses5 and ship a newer host toolchain that older Buildroot releases
# have trouble with. Works natively on both arm64 (Apple Silicon) and amd64.
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Buildroot host requirements (https://buildroot.org/downloads/manual/manual.html#requirement)
# plus a few tools used by the helper scripts (zip, file, nano, ssh client).
# sqlite3: x6100_gui/sql/CMakeLists.txt runs the host sqlite3 CLI to generate
# params.default.db from params.sql.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash bc binutils build-essential bzip2 ca-certificates cpio curl \
        file findutils g++ gcc git gzip less libelf-dev libncurses5-dev \
        libncursesw5-dev libssl-dev locales make nano openssh-client patch \
        perl python3 python3-dev python3-pip python3-setuptools rsync sed \
        sqlite3 tar unzip wget xz-utils zip \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# x6100_gui requires CMake >= 3.23. Ubuntu 22.04 ships 3.22 and Buildroot 2022.11
# would also only build 3.22 for the host, so install a newer one from PyPI.
# Pinned below 4.0, because CMake 4 refuses projects declaring < 3.5, which
# some Buildroot packages still do.
RUN pip3 install --no-cache-dir cmake==3.31.6

# Buildroot runs as root inside the container; host-tar's configure wants this.
ENV FORCE_UNSAFE_CONFIGURE=1

WORKDIR /work/AetherX6100Buildroot
CMD ["bash"]
