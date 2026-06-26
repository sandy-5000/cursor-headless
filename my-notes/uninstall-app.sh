#!/usr/bin/env bash
set -euo pipefail

APP_NAME="My Notes"
APP_PATH="/Applications/$APP_NAME.app"
DATA_DIR="$HOME/Library/Application Support/MyNotes"

PURGE_DATA=false

usage() {
    cat <<EOF
Uninstall $APP_NAME from this Mac.

Usage:
  ./uninstall-app.sh [--purge]

Options:
  --purge    Also delete saved notes in:
             $DATA_DIR
  -h, --help Show this help

Without --purge, your notes are kept on disk.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --purge) PURGE_DATA=true ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            usage
            exit 1
            ;;
    esac
done

removed=0

if [[ -d "$APP_PATH" ]]; then
    echo "Removing $APP_PATH..."
    rm -rf "$APP_PATH"
    removed=1
else
    echo "App not found in Applications: $APP_PATH"
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOCAL_APP="$ROOT/dist/$APP_NAME.app"
if [[ -d "$LOCAL_APP" ]]; then
    echo "Removing local build: $LOCAL_APP..."
    rm -rf "$LOCAL_APP"
    removed=1
fi

if [[ "$PURGE_DATA" == true ]]; then
    if [[ -d "$DATA_DIR" ]]; then
        echo "Removing saved notes: $DATA_DIR..."
        rm -rf "$DATA_DIR"
        removed=1
    else
        echo "No saved notes found at: $DATA_DIR"
    fi
else
    if [[ -d "$DATA_DIR" ]]; then
        echo ""
        echo "Your notes were kept at:"
        echo "  $DATA_DIR"
        echo ""
        echo "To delete them too, run:"
        echo "  ./uninstall-app.sh --purge"
    fi
fi

echo ""
if [[ "$removed" -eq 1 ]]; then
    echo "Uninstall complete."
else
    echo "Nothing to uninstall."
fi
