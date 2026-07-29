#!/bin/bash
#
# Installs all cosmic-epoch build requirements that I have found
# Some may not be needed, but I wanted to be thorough before starting
# I typically reboot after installing and configuring rustup/cargo/just

echo "=== Istalling Required Packages to Build COSMIC DE ==="

# Some of these are for packages that are not part of the build reqs for cosmic suite...yet

sudo apt update && sudo apt install \
  apt-utils \
  build-essential \
  clang \
  cmake \
  curl \
  dbus \
  debhelper \
  desktop-file-utils \
  devscripts \
  fonts-open-sans \
  git \
  git-lfs \
  intltool \
  imagemagick \
  libclang-dev \
  libdav1d-dev \
  libdbus-1-dev \
  libdisplay-info-dev \
  libegl1-mesa-dev \
  libegl-dev \
  libei-dev \
  libexpat1-dev \
  libflatpak-dev \
  libfontconfig-dev \
  libfreetype-dev \
  libgbm-dev \
  libgl-dev \
  libglib2.0-dev \
  libglvnd-dev \
  libgstreamer-plugins-bad1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer1.0-dev \
  libinput-dev \
  libpam0g-dev \
  libpipewire-0.3-dev \
  libpixman-1-dev \
  libpulse-dev \
  libseat-dev \
  libspa-0.2-dev \
  libssl-dev \
  libsystemd-dev \
  libudev-dev \
  libwayland-dev \
  libxcb1-dev \
  libxkbcommon-dev \
  lld \
  meson \
  mold \
  nano \
  nasm \
  ninja-build \
  pkg-config \
  rustup \
  sassc \
  tmux \
  udev

# === Install LFS support for git to clone all of the COSMIC DE Source Files ===
git lfs install

# === Configure rustup and install just ===
rustup toolchain install stable
#
# Install just via cargo
cargo install just
#
# export the just binary to your $PATH
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
#
# Source your modified .bashrc file or logout/login
source ~/.bashrc
# I typically reboot at this point
