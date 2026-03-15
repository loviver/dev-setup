#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Directorios globales
ICON_DIR="$HOME/.local/share/icons"
DESKTOP_DIR="$HOME/.local/share/applications"

msg()      { echo -e "${BLUE}::${NC} $1" >&2; }
msg_ok()   { echo -e "${GREEN}::${NC} $1" >&2; }
msg_warn() { echo -e "${YELLOW}::${NC} $1" >&2; }
msg_err()  { echo -e "${RED}::${NC} $1" >&2; }
msg_bold() { echo -e "${BOLD}$1${NC}" >&2; }

separator() {
  echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
}
