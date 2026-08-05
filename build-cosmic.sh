#!/bin/bash
#
# Make this build-cosmic.sh script executable
# chmod +x build-cosmic.sh
#
# Run build script with:
# ./build-cosmic.sh

set -euo pipefail

# ================== CONFIGURATION ==================
# This will appear in the Changelogs
# Edit to fit your needs
export DEBFULLNAME="Cosmic Builder"
export DEBEMAIL="cosmic-builder@cosmic-build.home.arpa"

# ================== DEBIAN RELEASE DETECTION ==================
DEB_CODENAME="trixie" # Default fallback
DEB_TAG="deb13"

if [[ -f /etc/os-release ]]; then
    source /etc/os-release

    case "${VERSION_CODENAME:-}" in
        trixie)
            DEB_CODENAME="trixie"
            DEB_TAG="deb13"
            ;;
        forky|sid)
            DEB_CODENAME="forky"
            DEB_TAG="deb14"
            ;;
        *)
            echo "Warning: Unrecognized release (${VERSION_CODENAME:-unknown}). Defaulting to trixie (deb13)."
            DEB_CODENAME="trixie"
            DEB_TAG="deb13"
            ;;
    esac
fi

# This ensures you can run this script from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_DIR="${SCRIPT_DIR}/cosmic-epoch"
REPO_DIR="$HOME/local-repo"
PATCH_DIR="${SCRIPT_DIR}/cosmic-patches"

# Edit Version to match cosmic-epoch release
COSMIC_VERSION="1.5.0"
BUILD_DATE=$(date +%Y%m%d)

# Formats output like: 1.5.0+deb13-20260804 or 1.5.0+deb14-20260804
FULL_VERSION="${COSMIC_VERSION}+${DEB_TAG}-${BUILD_DATE}"

# Log file output location
LOG_FILE="${SCRIPT_DIR}/build-${BUILD_DATE}.log"

# Send all script output (stdout & stderr) to both screen and logfile
exec > >(tee -a "$LOG_FILE") 2>&1

# ================== COLOR OUTPUT ==================
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}=== Starting COSMIC DE Build (${FULL_VERSION} on ${DEB_CODENAME}) ===${NC}"

# Ensure dch is installed before running
if ! command -v dch >/dev/null 2>&1; then
    echo -e "${RED}Error: 'dch' not found. Install with: sudo apt install devscripts${NC}"
    exit 1
fi

# ====================== CLONE SOURCE ======================
if [[ -d "$BASE_DIR" ]]; then
    rm -rf "$BASE_DIR"
fi

echo -e " ${BLUE}-> Cloning cosmic-epoch repository...${NC}"
git clone --recurse-submodules https://github.com/pop-os/cosmic-epoch "$BASE_DIR" >/dev/null 2>&1

if [[ ! -d "$BASE_DIR" ]]; then
    echo -e "${RED}Error: Failed to clone repository${NC}"
    exit 1
fi

cd "$BASE_DIR" || { echo -e "${RED}Error: Cannot cd to $BASE_DIR${NC}"; exit 1; }

# COSMIC EPOCH Source packages to build
SOURCE_COMPONENTS=(
    cosmic-icons cosmic-wallpapers cosmic-applets cosmic-applibrary
    cosmic-bg cosmic-comp cosmic-edit cosmic-files cosmic-greeter
    cosmic-idle cosmic-initial-setup cosmic-launcher cosmic-monitor
    cosmic-notifications cosmic-osd cosmic-panel cosmic-player
    cosmic-randr cosmic-screenshot cosmic-session cosmic-settings
    cosmic-settings-daemon cosmic-store cosmic-term cosmic-workspaces-epoch
    pop-launcher xdg-desktop-portal-cosmic
)

echo -e " ${BLUE}-> Building components...Can take a long while depending on CPU speed.${NC}"

for component in "${SOURCE_COMPONENTS[@]}"; do
    if [[ ! -d "$component" ]]; then
        continue
    fi

    if cd "$component" 2>/dev/null; then

        # Apply patches
        if [[ -f "$PATCH_DIR/${component}.control" ]]; then
            cp "$PATCH_DIR/${component}.control" debian/control
            echo -e "    ${BOLD}${GREEN}$component control file patched${NC}"
        fi
        if [[ -f "$PATCH_DIR/${component}.rules" ]]; then
            cp "$PATCH_DIR/${component}.rules" debian/rules
            chmod +x debian/rules
            echo -e "    ${BOLD}${GREEN}$component rules file patched${NC}"
        fi
        if [[ -f "$PATCH_DIR/${component}.justfile" ]]; then
            cp "$PATCH_DIR/${component}.justfile" justfile
            echo -e "    ${BOLD}${GREEN}$component justfile file patched${NC}"
        fi

        # === Override or Create Changelog ===
        if [[ -f debian/changelog ]]; then
            DEBFULLNAME="${DEBFULLNAME}" DEBEMAIL="${DEBEMAIL}" dch -v "${FULL_VERSION}" \
                   -D "unstable" \
                   --force-distribution \
                   "Local rebuild ${BUILD_DATE} for ${DEB_CODENAME}" 2>/dev/null || {
                echo -e "${RED}Error: dch failed to update changelog for $component${NC}"
                exit 1
            }
        else
            mkdir -p debian
            DEBFULLNAME="${DEBFULLNAME}" DEBEMAIL="${DEBEMAIL}" dch --create \
                   --package "${component}" \
                   -v "${FULL_VERSION}" \
                   -D "unstable" \
                   "Initial build for ${DEB_CODENAME}" 2>/dev/null || {
                echo -e "${RED}Error: dch failed to create changelog for $component${NC}"
                exit 1
            }
        fi

        # Build package
        if dpkg-buildpackage -b -d -us -uc >/dev/null 2>&1; then
            echo -e "    [${GREEN}OK${NC}] Built ${component}"
        else
            echo -e "    [${RED}FAIL${NC}] Build failed for $component"
            exit 1
        fi

        cd "$BASE_DIR" || { echo -e "${RED}Error: Failed to return to base dir${NC}"; exit 1; }
    fi
done

# ====================== DEBIAN META PACKAGE ======================
META_PKG="cosmic-debian-addons"

mkdir -p "$META_PKG/DEBIAN"
cp "$PATCH_DIR/${META_PKG}.control" "$META_PKG/DEBIAN/control"

cd "$META_PKG"
sed -i "s/^Version:.*/Version: ${FULL_VERSION}/" DEBIAN/control 2>/dev/null || true

if dpkg-deb --build --root-owner-group . "../${META_PKG}_${FULL_VERSION}_all.deb" >/dev/null 2>&1; then
    echo -e "    [${GREEN}OK${NC}] Built ${META_PKG}"
else
    echo -e "    [${RED}FAIL${NC}] Failed to build $META_PKG"
    exit 1
fi
cd "$BASE_DIR"

# Cleanup extra un-needed temporary build files
rm -f "$BASE_DIR"/*dbgsym* "$BASE_DIR"/*.buildinfo "$BASE_DIR"/*.changes 2>/dev/null || true

# ====================== LOCAL REPOSITORY SETUP ======================
if [[ -d "$REPO_DIR" ]]; then
    rm -f "${REPO_DIR}-backup-"*.tar.gz 2>/dev/null || true

    TAR_BACKUP="${REPO_DIR}-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    echo -e " ${BLUE}-> Backing up old repository to $(basename "$TAR_BACKUP")...${NC}"
    tar -czf "$TAR_BACKUP" -C "$(dirname "$REPO_DIR")" "$(basename "$REPO_DIR")"

    rm -rf "$REPO_DIR"
fi

echo -e " ${BLUE}-> Creating APT repository indexes for ${DEB_CODENAME}...${NC}"

# Define standard Debian repo paths dynamically based on target release
DIST_DIR="$REPO_DIR/dists/${DEB_CODENAME}"
BINARY_DIR="$DIST_DIR/main/binary-amd64"
POOL_DIR="$REPO_DIR/pool/main"

mkdir -p "$BINARY_DIR" "$POOL_DIR"

# Move all .deb packages into the pool
mv "$BASE_DIR"/*.deb "$POOL_DIR/" 2>/dev/null || true

# Generate Packages & Packages.gz inside the binary architecture directory
cd "$REPO_DIR"
apt-ftparchive packages pool/main > "$BINARY_DIR/Packages" 2>/dev/null
gzip -9c "$BINARY_DIR/Packages" > "$BINARY_DIR/Packages.gz"

# Generate Release metadata file inside dists/${DEB_CODENAME}
cat > "$DIST_DIR/Release" <<EOF
Origin: Local COSMIC Build
Label: Cosmic Debian (${DEB_CODENAME})
Suite: ${DEB_CODENAME}
Codename: ${DEB_CODENAME}
Components: main
Architectures: amd64
Date: $(date -u +"%a, %d %b %Y %T %Z")
EOF

# Append package checksums automatically for the release
apt-ftparchive release "$DIST_DIR" >> "$DIST_DIR/Release" 2>/dev/null

echo -e " ${BOLD}${RED}-> Removing cosmic-epoch build directory to clear up disk space.${NC}"
rm -rf "$BASE_DIR"
echo -e "${GREEN}========================================${NC}"
echo -e "${BOLD}${GREEN}Build script completed successfully!${NC}"
echo "Repository ready at: $REPO_DIR"
echo ""
echo "Host packages directly via HTTP ***Local Lan Testing Only*** (e.g. python3 -m http.server 8080 -d $REPO_DIR)"
echo "Use a proper HTTP server if hosting via internet, the python module should only be used for local lan testing!"
echo ""
echo "Client machine sources list setup example (Change to match your build machine IP or hostname):"
echo "   deb [trusted=yes] http://cosmic-build:8080 ${DEB_CODENAME} main"
echo ""
echo "Or for installing on the same machine it was built on:"
echo "   deb [trusted=yes] file://$REPO_DIR ${DEB_CODENAME} main"
echo ""
echo "Then run: sudo apt update && sudo apt install cosmic-session cosmic-initial-setup cosmic-debian-addons"
echo -e "${GREEN}========================================${NC}"
