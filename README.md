# cosmic-debian
Basic scripts I use to build COSMIC Epoch DE on Debian Trixie.
All this script does is build COSMIC EPOCH using common Debian tools when cloning from the github repo using
the debian/control and associated files that System76 provides. And some small edits by me to the control files
to remove anything Pop_Os specific that doesn't come from the Debian Repos. 

I  would suggest you try in a VM first to see if you want to install on bare-metal, or alongside a DE like Gnome or KDE. I have tested my built packages on a minimal Debian Trixie install (Standard System Utilities is the only thing I install via the Debian netinstall ISO), against a new updated install of Pop!_OS and I have almost the same warnings/errors as they appear in Pop_OS when starting COSMIC Apps from a terminal, so I guess I'm doing something OK as far as the built packages matching pretty much what System76 COSMIC DE is building. The only difference is in the naming of the paths for the build; they build under /build and I build under /home/cosmic, but the warnings/errors match.

Change these in build-cosmic.sh to update the changelog/package info to fit your needs:
```
export DEBFULLNAME="Cosmic Builder"
export DEBEMAIL="cosmic-builder@cosmic-build.home.arpa"
```

Currently will build COSMIC Epoch 1.5.0
```
COSMIC_VERSION="1.5.0"
```
