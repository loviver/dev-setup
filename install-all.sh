#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

show_usage() {
  cat <<EOF
Instalador de aplicaciones (modo rápido)

Uso: $(basename "$0") [OPCIONES]

Opciones:
  all       Instalar todas las aplicaciones (por defecto)
  cursor    Instalar solo Cursor AI
  warp      Instalar solo Warp Terminal
  vscode    Instalar solo Visual Studio Code
  -h        Mostrar esta ayuda

Para menú interactivo con más opciones, usa: ./manager.sh

EOF
}

# Delega al nuevo sistema
exec_manager() {
  bash "$SCRIPT_DIR/manager.sh" "$@"
}

main() {
  local mode="${1:-all}"

  case "$mode" in
    -h|--help)
      show_usage
      exit 0
      ;;
    cursor|warp|vscode)
      exec_manager "$mode" install
      ;;
    all)
      exec_manager all install
      ;;
    *)
      echo "Error: opción desconocida '$mode'"
      show_usage
      exit 1
      ;;
  esac
}

main "$@"
