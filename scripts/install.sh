#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
"$ROOT/scripts/build-app.sh" "$ROOT/dist"
STAGE="$(mktemp -d /Applications/.codex-meter-zh-cn-install.XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT
APP_PATH="/Applications/Codex Meter 中文版.app"
BACKUP="/Applications/.Codex Meter 中文版.previous.app"
HAD_BACKUP=0
NEW_APP_INSTALLED=0

restore_previous() {
  if (( NEW_APP_INSTALLED )); then
    rm -rf "$APP_PATH"
  fi
  if (( HAD_BACKUP )); then
    mv "$BACKUP" "$APP_PATH"
  fi
}

ditto --norsrc --noextattr --noqtn --noacl "$ROOT/dist/Codex Meter 中文版.app" "$STAGE/Codex Meter 中文版.app"
xattr -cr "$STAGE/Codex Meter 中文版.app"
codesign --force --deep --sign - "$STAGE/Codex Meter 中文版.app"
codesign --verify --deep --strict "$STAGE/Codex Meter 中文版.app"

if [[ -e "$APP_PATH" || -L "$APP_PATH" ]]; then
  rm -rf "$BACKUP"
  mv "$APP_PATH" "$BACKUP"
  HAD_BACKUP=1
fi

if ! mv "$STAGE/Codex Meter 中文版.app" "$APP_PATH"; then
  restore_previous
  exit 1
fi
NEW_APP_INSTALLED=1

if ! codesign --verify --deep --strict "$APP_PATH"; then
  restore_previous
  exit 1
fi

rm -rf "$BACKUP"
open "$APP_PATH"
echo "Installed and opened $APP_PATH"
