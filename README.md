# cosmic-debian
Basic scripts I use to build COSMIC Epoch DE on Debian Trixie/Forky (Have tested it on Forky, I just don't run Forky/Testing as a daily driver. The `install-build.sh` installs the build requirements, some may not be needed, but I wanted to make sure I had everything needed before starting. The `find-depends.sh` I will use when changes are made to the cosmic-epoch debian/control files to see if my scripts may need updating. The `build-cosmic.sh` is the script that actually builds the packages.

All this script (build-cosmic.sh) does is build COSMIC EPOCH using common Debian tools when cloning from the github repo using the debian/control and associated files that System76 provides. And some small edits (cosmic-patches/) by me to the control files to remove anything Pop_Os specific that doesn't come from the Debian Repos.

I build in an `incus` Debian 13/14 system container, or `incus` Debian 13/14 VM. The container builds faster because I don't limit the number of CPUs/Ram/Disk like I do for a VM. My VM setup for something like this is 6-8 cpu, 12gb ram, 100gb disk. But both are using a network bridge so other machines on my network can see the build/repo. 

I  would suggest you try the desktop on a VM first to see if you want to install on bare-metal, or alongside a DE like Gnome or KDE. I have tested my built packages on a minimal Debian Trixie install (Standard System Utilities is the only thing I install via the Debian netinstall ISO), against a new updated install of Pop!_OS and I have almost the same warnings/errors as they appear in Pop_OS when starting COSMIC Apps from a terminal, so I guess I'm doing something OK as far as the built packages matching pretty much what System76 COSMIC DE is building. The only difference is in the naming of the paths for the build; they build under /build and I build under /home/cosmic, but the warnings/errors match.

Change these in build-cosmic.sh to update the changelog/package info to fit your needs:
```
export DEBFULLNAME="Cosmic Builder"
export DEBEMAIL="cosmic-builder@cosmic-build.home.arpa"
```
The build script should automatically detect which Debian Release you are using (Trixie or Forky/Testing)

Currently is setup to build COSMIC Epoch 1.5.0. Can change this later as different versions are released:
```
COSMIC_VERSION="1.5.0"
```

After my repo is setup (On the same machine as the build was performed on), I create a `/etc/apt/sources.d/cosmic.list` on a client machine, and its a simple `deb [trusted=yes] http://<name or ip>:8080 trixie main` or `deb [trusted=yes] http://<name or ip>:8080 forky main`. You could setup Apache or nginx as a webserver and host the packages that way, but the simple `python3 -m http.server 8080 -d /path/to/local-repo` works for my local lan. I do use `tmux` so I can exit out of the session and keep the repo up and running. I wouldn't host this repo on the internet using the python3 module though, just my local lan. After that's all done I'd do a `sudo apt update && sudo apt upgrade` on the client and then:
```
sudo apt install cosmic-initial-setup cosmic-session cosmic-debian-addons
```

And that will install all the required COSMIC DE Software and dependencies needed. I haven't really tested installing alongside Gnome or other DEs for a bit, and when I do it's in a VM. Last time I did, when installing the COSMIC packages, you will have a chance to select either gdm3/sddm or cosmic-greeter as the login manager, I typically use cosmic-greeter, but it works either way. Select the cog to select your session (cosmic/gnome/kde) and finish your login.
