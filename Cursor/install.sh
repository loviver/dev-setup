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
source "$SCRIPT_DIR/lib/native.sh"

install_appimage() {
  echo "Modo: AppImage"
  echo ""
  
  echo "Preparando directorios..."
  setup_directories "$INSTALL_DIR" "$ICON_DIR" "$DESKTOP_DIR"
  echo "Directorio de instalación: $INSTALL_DIR"
  echo ""
  
  echo "Obteniendo URL de descarga..."
  local final_url
  if ! final_url=$(resolve_download_url "$DOWNLOAD_URL_APPIMAGE"); then
    echo "Error: no se pudo obtener la URL de descarga"
    return 1
  fi
  echo ""
  
  local filename
  filename=$(basename "$final_url")
  
  if ! validate_appimage "$filename"; then
    return 1
  fi
  
  echo "AppImage detectado: $filename"
  echo ""
  
  if ! download_appimage "$final_url" "$INSTALL_DIR" "$filename"; then
    return 1
  fi
  echo ""
  
  local exec_path="$INSTALL_DIR/$filename"
  
  if ! install_icon "$ICON_URL" "$ICON_DIR" "$ICON_NAME"; then
    return 1
  fi
  echo ""
  
  echo "Creando entrada de escritorio..."
  create_desktop_entry "$DESKTOP_DIR" "$DESKTOP_FILE" "$APP_NAME" "$APP_COMMENT" "$exec_path" "$ICON_DIR/$ICON_NAME" "$CATEGORIES"
  echo ""
  
  echo "Actualizando base de datos de escritorio..."
  update_desktop_database "$DESKTOP_DIR"
  echo ""
  
  echo "$APP_NAME instalado correctamente en $exec_path"
}

install_native() {
  echo "Modo: Nativo"
  echo ""
  
  echo "Preparando directorios..."
  setup_directories "$INSTALL_DIR_NATIVE" "$ICON_DIR" "$DESKTOP_DIR"
  echo "Directorio de instalación: $INSTALL_DIR_NATIVE"
  echo ""
  
  echo "Obteniendo URL de descarga..."
  local final_url
  if ! final_url=$(resolve_download_url "$DOWNLOAD_URL_NATIVE"); then
    echo "Error: no se pudo obtener la URL de descarga"
    return 1
  fi
  echo ""
  
  if ! download_native "$final_url" "$INSTALL_DIR_NATIVE"; then
    return 1
  fi
  echo ""
  
  local exec_path
  if [[ "$final_url" == *.rpm ]]; then
    exec_path=$(get_executable_path "")
  else
    exec_path=$(get_executable_path "$INSTALL_DIR_NATIVE")
  fi
  
  if ! install_icon "$ICON_URL" "$ICON_DIR" "$ICON_NAME"; then
    return 1
  fi
  echo ""
  
  echo "Creando entrada de escritorio..."
  create_desktop_entry "$DESKTOP_DIR" "$DESKTOP_FILE" "$APP_NAME" "$APP_COMMENT" "$exec_path" "$ICON_DIR/$ICON_NAME" "$CATEGORIES"
  echo ""
  
  echo "Actualizando base de datos de escritorio..."
  update_desktop_database "$DESKTOP_DIR"
  echo ""
  
  echo "$APP_NAME instalado correctamente en $exec_path"
}

main() {
  echo "Instalando $APP_NAME"
  echo "Tipo de instalación: $INSTALL_TYPE"
  echo ""
  
  case "$INSTALL_TYPE" in
    appimage)
      install_appimage
      ;;
    native)
      install_native
      ;;
    *)
      echo "Error: tipo de instalación inválido '$INSTALL_TYPE'"
      echo "Tipos válidos: appimage, native"
      exit 1
      ;;
  esac
}

main "$@"
