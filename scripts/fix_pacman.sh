#!/bin/bash
set -e

# Usage: ./fix_pacman.sh [path_to_pacman_file]

fix_package() {
    local PACMAN_FILE="$1"
    if [ ! -f "$PACMAN_FILE" ]; then
        echo "Error: File $PACMAN_FILE not found."
        return 1
    fi

    local DEST_DIR=$(dirname "$PACMAN_FILE")
    local TEMP_DIR=$(mktemp -d)
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
    # Restore underscores in pkgname (fastforge converts _ to -)
    sed -i 's/^pkgname = li-curriculum-table/pkgname = li_curriculum_table/' .PKGINFO
    # Append pkgrel=-1 if missing (pacman requires pkgver-pkgrel format)
    if ! grep -q "^pkgver = .*-[0-9]" .PKGINFO; then
        sed -i 's/^pkgver = \(.*\)/pkgver = \1-1/' .PKGINFO
    fi
    sed -i 's/^groups =/group =/' .PKGINFO

    # 3. Regenerate .MTREE (include opt/ if it exists: 0.6.5 puts app in usr/, 0.6.8+ in opt/)
    ARCHIVE_DIRS=".PKGINFO .INSTALL usr"
    [ -d opt ] && ARCHIVE_DIRS="$ARCHIVE_DIRS opt"
    bsdtar -czf .MTREE --format=mtree --options='!all,use-set,type,uid,gid,mode,time,size,md5,sha256,link' $ARCHIVE_DIRS

    # 4. Repack (use same ARCHIVE_DIRS, substitute .PKGINFO/.INSTALL with .MTREE)
    REPACK_DIRS=".MTREE .PKGINFO .INSTALL usr"
    [ -d opt ] && REPACK_DIRS="$REPACK_DIRS opt"
    bsdtar -cf - $REPACK_DIRS | xz -c -z - > fixed.pacman

    popd > /dev/null

    mv "$TEMP_DIR/fixed.pacman" "$PACMAN_FILE"
    rm -rf "$TEMP_DIR"

    echo "Fixed: $PACMAN_FILE"
}

if [ -n "$1" ]; then
    fix_package "$1"
else
    echo "No file provided, searching in dist/..."
    FILES=$(find dist -name "*.pacman")
    if [ -z "$FILES" ]; then
        echo "Error: No .pacman files found in dist/"
        exit 1
    fi
    for f in $FILES; do
        fix_package "$f"
    done
fi
