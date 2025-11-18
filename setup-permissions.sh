#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Configurando permisos de ejecución..."

find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "Permisos aplicados a todos los archivos .sh"
