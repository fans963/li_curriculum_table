#!/usr/bin/env bash
set -euo pipefail

OWNER="fans963"
REPO="li_curriculum_table"
OUTDIR="${OUTDIR:-./dist}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── 加载 .env 中的 GITHUB_TOKEN ───────────────────────────────────────────
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

# ── GitHub API 认证 ────────────────────────────────────────────────────────
CURL_AUTH=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  CURL_AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

api() {
  curl -fsS "${CURL_AUTH[@]}" "$1" 2>/dev/null
}

# ── 版本号 ─────────────────────────────────────────────────────────────────
resolve_version() {
  api "https://api.github.com/repos/$OWNER/$REPO/releases/latest" \
    | grep '"tag_name":' | head -1 \
    | sed 's/.*"tag_name": *"v\?\([^"]*\)".*/\1/'
}

# ── 列出所有 asset 文件名 ──────────────────────────────────────────────────
list_assets() {
  local tag="$1" json names
  json=$(api "https://api.github.com/repos/$OWNER/$REPO/releases/tags/v$tag")

  if command -v jq &>/dev/null; then
    names=$(echo "$json" | jq -r '.assets[]?.name // empty' 2>/dev/null)
  elif command -v python3 &>/dev/null; then
    names=$(echo "$json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in data.get('assets', []):
    print(a['name'])
" 2>/dev/null)
  else
    names=$(echo "$json" | grep -o '"name": *"[^"]*"' | grep -v 'tag_name' \
      | sed 's/.*"name": *"\([^"]*\)".*/\1/')
  fi

  echo "$names" | grep -v 'debug-symbols' || true
}

# ── 下载单个文件 ───────────────────────────────────────────────────────────
download_one() {
  local url="$1" name="$2"
  echo "  ↓ $name"
  if curl -fSL -o "$OUTDIR/$name" --connect-timeout 10 --max-time 900 -# "$url" 2>&1; then
    return 0
  else
    echo "     ✗ failed"
    rm -f "$OUTDIR/$name"
    return 1
  fi
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
  local filter="${1:-all}"
  local version asset_names assets name url count=0 fail=0

  version=$(resolve_version)
  [ -z "$version" ] && echo "ERROR: cannot determine version" >&2 && exit 1

  mkdir -p "$OUTDIR"

  asset_names=$(list_assets "$version")
  if [ -z "$asset_names" ]; then
    echo "ERROR: no assets found for v$version (API rate limit? token set?)" >&2
    exit 1
  fi

  echo "Release v$version — $(echo "$asset_names" | wc -l) assets"
  echo ""

  # Filter
  case "$filter" in
    all)     assets="$asset_names" ;;
    android) assets=$(echo "$asset_names" | grep -i 'apk') ;;
    ios)     assets=$(echo "$asset_names" | grep -i 'ipa') ;;
    linux)   assets=$(echo "$asset_names" | grep -iE 'linux|appimage|\.deb|\.rpm|pacman|pkg\.tar') ;;
    windows) assets=$(echo "$asset_names" | grep -iE 'windows|\.exe|\.msix') ;;
    macos)   assets=$(echo "$asset_names" | grep -iE 'macos|\.dmg|\.pkg') ;;
    desktop) assets=$(echo "$asset_names" | grep -ivE 'apk|ipa') ;;
    mobile)  assets=$(echo "$asset_names" | grep -iE 'apk|ipa') ;;
    *)       echo "Unknown filter: $filter" >&2; exit 1 ;;
  esac

  [ -z "$assets" ] && echo "No assets matched '$filter'" && exit 1

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    url="https://github.com/$OWNER/$REPO/releases/download/v$version/$name"
    if download_one "$url" "$name"; then
      count=$((count + 1))
    else
      fail=$((fail + 1))
    fi
  done <<< "$assets"

  echo ""
  echo "Done: $count downloaded, $fail failed → $OUTDIR"
  du -sh "$OUTDIR"/* 2>/dev/null || true
}

main "$@"
