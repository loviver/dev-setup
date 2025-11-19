#!/bin/bash

if [[ -z "${DOWNLOAD_URL_APPIMAGE:-}" ]] || [[ "${DOWNLOAD_URL_APPIMAGE}" =~ ^[[:space:]]*# ]]; then
  INSTALL_TYPE="${INSTALL_TYPE:-native}"
else
  INSTALL_TYPE="${INSTALL_TYPE:-appimage}"
fi

APP_NAME="Warp"
APP_COMMENT="Warp Terminal"
#DOWNLOAD_URL_APPIMAGE="https://app.warp.dev/download?package=appimage"
DOWNLOAD_URL_NATIVE_BASE="https://app.warp.dev/download?package=rpm"
ICON_URL="https://user-images.githubusercontent.com/85056161/221151383-dee5374b-03d9-4548-a0fd-35dfc7ea0f5b.png"
ICON_NAME="warp.png"
DESKTOP_FILE="warp.desktop"
CATEGORIES="System;Utility;TerminalEmulator;"
INSTALL_DIR_NATIVE="/usr/local/bin"
