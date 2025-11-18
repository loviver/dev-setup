#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

show_usage() {
  cat <<EOF
Instalador de aplicaciones

Uso: $(basename "$0") [OPCIONES]

Opciones:
  all       Instalar todas las aplicaciones (por defecto)
  cursor    Instalar solo Cursor AI
  warp      Instalar solo Warp Terminal
  -h        Mostrar esta ayuda

EOF
}

install_app() {
  local app_dir="$1"
  local app_name="$2"
  
  if [[ ! -f "$app_dir/install.sh" ]]; then
    echo "Error: no se encuentra $app_dir/install.sh"
    return 1
  fi
  
  echo ""
  echo "Instalando $app_name"
  bash "$app_dir/install.sh"
}

main() {
  local mode="${1:-all}"
  
  case "$mode" in
    -h|--help)
      show_usage
      exit 0
      ;;
    cursor)
      install_app "$SCRIPT_DIR/Cursor" "Cursor AI"
      ;;
    warp)
      install_app "$SCRIPT_DIR/Warp" "Warp Terminal"
      ;;
    all)
      install_app "$SCRIPT_DIR/Cursor" "Cursor AI"
      install_app "$SCRIPT_DIR/Warp" "Warp Terminal"
      ;;
    *)
      echo "Error: opción desconocida '$mode'"
      show_usage
      exit 1
      ;;
  esac
  
  echo ""
  echo "Instalación completada"
}

main "$@"
