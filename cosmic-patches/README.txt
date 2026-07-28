These files replace/remove various package dependencies in the debian/control files and allows COSMIC DE to install and run on Debian. Some COSMIC-DE packages required Pop_Os specific packages outside of the COSMIC-EPOCH github repo, so I removed those dependecies and replace then with substitutes. So far I have not run into any major problems with this method.

I have also created a meta package "cosmic-trixie-addons" that will install packages for QoL issues like bluetooth, flatpak, firefox, etc, etc. System76 builds COSMIC to run on Pop_Os, so they have everything already setup for these types of issues. I'm installing COSMIC on a bare minimum install of Debian, or alongside Gnome/Plasma/Etc, so needed to add in some support for a desktop envirement, and didn't want to modify the COSMIC debian/cntrol files too much.

There is also a replacement justfile/rules for a package that fails to build for me due to a unset env variable.

