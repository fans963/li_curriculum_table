#!/bin/bash
set -e

# Usage: ./fix_pacman.sh [path_to_pacman_file]

PACMAN_FILE=$1

if [ -z "$PACMAN_FILE" ]; then
    echo "No file provided, searching in dist/..."
    # Find the .pacman file, usually in dist/1.0.1/
    PACMAN_FILE=$(find dist -name "*.pacman" | head -n 1)
fi

if [ -z "$PACMAN_FILE" ] || [ ! -f "$PACMAN_FILE" ]; then
    echo "Error: Pacman file not found. Usage: $0 <path_to_pacman_file>"
    exit 1
fi

DEST_DIR=$(dirname "$PACMAN_FILE")
TEMP_DIR=$(mktemp -d)
echo "Rebuilding pacman package $PACMAN_FILE in $TEMP_DIR..."

# 1. Extract the original package
# FastForge generated .pacman is actually a .pkg.tar.xz (or similar tar xz)
xz -d -c "$PACMAN_FILE" | bsdtar -xf - -C "$TEMP_DIR"

pushd "$TEMP_DIR" > /dev/null

# 2. Fix .PKGINFO
# - Remove parentheses
# - Add spaces around =
# - Fix pkgver (append -1 pkgrel)
# - Rename groups to group (standard PKGINFO field)
sed -i 's/(//g; s/)//g' .PKGINFO
sed -i 's/=/ = /g' .PKGINFO
# Ensure pkgver doesn't already have -1
if [[ ! $(grep "^pkgver =" .PKGINFO) =~ -[0-9]+ ]]; then
    sed -i 's/^pkgver = \(.*\)/pkgver = \1-1/' .PKGINFO
fi
sed -i 's/^groups =/group =/' .PKGINFO

# Read metadata for naming
PKGNAME=$(grep "^pkgname =" .PKGINFO | cut -d' ' -f3)
PKGVER=$(grep "^pkgver =" .PKGINFO | cut -d' ' -f3)
ARCH=$(grep "^arch =" .PKGINFO | cut -d' ' -f3)

NEW_FILENAME="${PKGNAME}-${PKGVER}-${ARCH}.pkg.tar.xz"

# 3. Regenerate .MTREE
# options inherited from fastforge source
bsdtar -czf .MTREE --format=mtree --options='!all,use-set,type,uid,gid,mode,time,size,md5,sha256,link' .PKGINFO .INSTALL usr

# 4. Repack
bsdtar -cf - .MTREE .PKGINFO .INSTALL usr | xz -c -z - > "$NEW_FILENAME"

popd > /dev/null

# 5. Cleanup
mv "$TEMP_DIR/$NEW_FILENAME" "$DEST_DIR/$NEW_FILENAME"
rm -rf "$TEMP_DIR"

echo "Success! Fixed package created: $DEST_DIR/$NEW_FILENAME"
