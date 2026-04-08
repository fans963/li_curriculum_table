#!/usr/bin/env bash
set -euo pipefail

# Package Flutter Linux bundle into deb, rpm and pacman packages via fpm.
# Requirements:
#   - flutter
#   - fpm (gem install --no-document fpm)
#
# Example:
#   scripts/package_linux.sh
#   scripts/package_linux.sh --types deb,rpm --version 1.2.3 --maintainer "fan <fan@example.com>"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC_FILE="$ROOT_DIR/pubspec.yaml"

APP_NAME="$(awk '/^name:/ {print $2; exit}' "$PUBSPEC_FILE")"
DISPLAY_NAME="$APP_NAME"
VERSION="$(awk '/^version:/ {print $2; exit}' "$PUBSPEC_FILE" | cut -d+ -f1)"
MAINTAINER="Packager <packager@example.com>"
DESCRIPTION="Flutter desktop application"
LICENSE="Proprietary"
URL="https://example.com"
BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
OUT_DIR="$ROOT_DIR/build/linux/packages"
TYPES="deb,rpm,pacman"
BUILD_FIRST="true"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --app-name NAME          Package/app name (default: from pubspec name)
  --display-name NAME      Desktop display name (default: app name)
  --version VERSION        Package version (default: from pubspec)
  --maintainer TEXT        Maintainer field
  --description TEXT       Description text
  --license TEXT           License field (default: Proprietary)
  --url URL                Project URL
  --bundle-dir PATH        Flutter Linux bundle dir
  --out-dir PATH           Output package dir
  --types LIST             Comma-separated package types: deb,rpm,pacman
  --build-first true|false Run flutter build linux --release first
  -h, --help               Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name) APP_NAME="$2"; shift 2 ;;
    --display-name) DISPLAY_NAME="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --maintainer) MAINTAINER="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --license) LICENSE="$2"; shift 2 ;;
    --url) URL="$2"; shift 2 ;;
    --bundle-dir) BUNDLE_DIR="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --types) TYPES="$2"; shift 2 ;;
    --build-first) BUILD_FIRST="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

normalize_arch() {
  case "$(uname -m)" in
    x86_64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "$(uname -m)" ;;
  esac
}

deb_arch_from_uname() {
  case "$1" in
    x86_64) echo "amd64" ;;
    arm64) echo "arm64" ;;
    *) echo "$1" ;;
  esac
}

rpm_arch_from_uname() {
  case "$1" in
    x86_64) echo "x86_64" ;;
    arm64) echo "aarch64" ;;
    *) echo "$1" ;;
  esac
}

pacman_arch_from_uname() {
  case "$1" in
    x86_64) echo "x86_64" ;;
    arm64) echo "aarch64" ;;
    *) echo "$1" ;;
  esac
}

require_cmd flutter
require_cmd fpm

if [[ "$BUILD_FIRST" == "true" ]]; then
  echo "==> Building Flutter Linux release bundle..."
  (cd "$ROOT_DIR" && flutter build linux --release)
fi

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "Bundle directory not found: $BUNDLE_DIR" >&2
  echo "Run: flutter build linux --release" >&2
  exit 1
fi

if [[ ! -x "$BUNDLE_DIR/$APP_NAME" ]]; then
  echo "Binary not found or not executable: $BUNDLE_DIR/$APP_NAME" >&2
  echo "Tip: pass --app-name if binary name differs from pubspec name." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

STAGE_DIR="$TMP_DIR/stage"
mkdir -p "$STAGE_DIR/opt/$APP_NAME"
mkdir -p "$STAGE_DIR/usr/bin"
mkdir -p "$STAGE_DIR/usr/share/applications"

cp -a "$BUNDLE_DIR/." "$STAGE_DIR/opt/$APP_NAME/"

cat >"$STAGE_DIR/usr/bin/$APP_NAME" <<EOF
#!/usr/bin/env bash
exec /opt/$APP_NAME/$APP_NAME "\$@"
EOF
chmod +x "$STAGE_DIR/usr/bin/$APP_NAME"

cat >"$STAGE_DIR/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Name=$DISPLAY_NAME
Comment=$DESCRIPTION
Exec=/usr/bin/$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Utility;
EOF

ICON_CANDIDATES=(
  "$ROOT_DIR/assets/icon/icon.png"
  "$ROOT_DIR/linux/icon.png"
)
for icon in "${ICON_CANDIDATES[@]}"; do
  if [[ -f "$icon" ]]; then
    mkdir -p "$STAGE_DIR/usr/share/icons/hicolor/256x256/apps"
    cp "$icon" "$STAGE_DIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
    break
  fi
done

IFS=',' read -r -a TYPE_ARRAY <<<"$TYPES"
HOST_ARCH="$(normalize_arch)"

for pkg_type in "${TYPE_ARRAY[@]}"; do
  pkg_type="${pkg_type// /}"
  [[ -z "$pkg_type" ]] && continue

  case "$pkg_type" in
    deb) pkg_arch="$(deb_arch_from_uname "$HOST_ARCH")" ;;
    rpm) pkg_arch="$(rpm_arch_from_uname "$HOST_ARCH")" ;;
    pacman) pkg_arch="$(pacman_arch_from_uname "$HOST_ARCH")" ;;
    *)
      echo "Unsupported package type: $pkg_type" >&2
      exit 1
      ;;
  esac

  echo "==> Packaging $pkg_type ($pkg_arch)..."
  fpm \
    -s dir \
    -t "$pkg_type" \
    -n "$APP_NAME" \
    -v "$VERSION" \
    --iteration 1 \
    --architecture "$pkg_arch" \
    --license "$LICENSE" \
    --maintainer "$MAINTAINER" \
    --description "$DESCRIPTION" \
    --url "$URL" \
    --prefix / \
    -C "$STAGE_DIR" \
    --package "$OUT_DIR" \
    .
done

echo
echo "Done. Packages are in: $OUT_DIR"
ls -lh "$OUT_DIR"
