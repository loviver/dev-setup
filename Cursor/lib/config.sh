#!/bin/bash

if [[ -z "${DOWNLOAD_URL_APPIMAGE:-}" ]] || [[ "${DOWNLOAD_URL_APPIMAGE}" =~ ^[[:space:]]*# ]]; then
  INSTALL_TYPE="${INSTALL_TYPE:-native}"
else
  INSTALL_TYPE="${INSTALL_TYPE:-appimage}"
fi

APP_NAME="Cursor AI"
APP_COMMENT="AI Code Editor"
#DOWNLOAD_URL_APPIMAGE="https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/2.0"
DOWNLOAD_URL_NATIVE="https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/2.0"
ICON_URL="https://cursor.com/marketing-static/_next/image?url=%2Fmarketing-static%2Fdownload%2Fapp-icon-25d-light.png&w=3840&q=70"
ICON_NAME="cursor.png"
DESKTOP_FILE="cursor.desktop"
CATEGORIES="Development;IDE;"
INSTALL_DIR_NATIVE="$HOME/.local/share/cursor"
