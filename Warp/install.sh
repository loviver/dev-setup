#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/../bin"
ICON_DIR="$HOME/.local/share/icons"
DESKTOP_DIR="$HOME/.local/share/applications"

source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/directories.sh"
source "$SCRIPT_DIR/lib/download.sh"
source "$SCRIPT_DIR/lib/desktop.sh"

main() {
  echo "Instalando $APP_NAME"
  echo ""
  
  echo "Preparando directorios..."
  setup_directories "$INSTALL_DIR" "$ICON_DIR" "$DESKTOP_DIR"
  echo "Directorio de instalación: $INSTALL_DIR"
  echo ""
  
  echo "Obteniendo URL de descarga..."
  local final_url
  if ! final_url=$(resolve_download_url "$DOWNLOAD_URL"); then
    echo "Error: no se pudo obtener la URL de descarga"
    exit 1
  fi
  echo ""
  
  local filename
  filename=$(basename "$final_url")
  
  if ! validate_appimage "$filename"; then
    exit 1
  fi
  
  echo "AppImage detectado: $filename"
  echo ""
  
  if ! download_appimage "$final_url" "$INSTALL_DIR" "$filename"; then
    exit 1
  fi
  echo ""
  
  if ! install_icon "$ICON_URL" "$ICON_DIR" "$ICON_NAME"; then
    exit 1
  fi
  echo ""
  
  echo "Creando entrada de escritorio..."
  create_desktop_entry "$DESKTOP_DIR" "$DESKTOP_FILE" "$APP_NAME" "$APP_COMMENT" "$INSTALL_DIR/$filename" "$ICON_DIR/$ICON_NAME" "$CATEGORIES"
  echo ""
  
  echo "Actualizando base de datos de escritorio..."
  update_desktop_database "$DESKTOP_DIR"
  echo ""
  
  echo "$APP_NAME instalado correctamente en $INSTALL_DIR/$filename"
}

main "$@"
