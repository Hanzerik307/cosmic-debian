# cosmic-debian
Basic scripts I use to build COSMIC Epoch DE on Debian Trixie.
All this script does is build COSMIC EPOCH using common Debian tools, when cloned from the github repo using
the debian/control and associated files that System76 provides. And some small edits by me to the control files
to remove anything Pop_Os specific that doesn't come from the Debian Repos. 

So some things may or may not work correctly. I would suggest you try in a VM first to see if you want
to install on bare-metal, or alongside a DE like Gnome or KDE.

Change these in build-cosmic.sh if you want the changelog to match your info:
```
export DEBFULLNAME="Cosmic Builder"
export DEBEMAIL="cosmic-builder@cosmic-build.home.arpa"
```

Currently will build COSMIC Epoch 1.5.0
```
COSMIC_VERSION="1.5.0"
```
