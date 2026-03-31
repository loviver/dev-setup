#!/bin/bash

# Devuelve la ruta real del ejecutable dentro de INSTALL_DIR
# Usa EXEC_SUBPATH si está definido, si no busca EXEC_NAME directamente
_tarball_exec_path() {
  local install_dir="$1"
  local exec_name="$2"
  local subpath="${EXEC_SUBPATH:-}"

  if [[ -n "$subpath" ]]; then
    echo "$install_dir/$subpath"
  else
    echo "$install_dir/$exec_name"
  fi
}

# Instala una app desde tarball (tar.gz)
# Extrae a INSTALL_DIR y crea symlink en BIN_DIR
tarball_install() {
  local url="$1"
  local install_dir="$2"
  local bin_dir="${3:-$HOME/.local/bin}"

  local temp_file
  temp_file=$(mktemp --suffix=.tar.gz)

  msg "Descargando desde $url"
  if ! curl -gL --progress-bar --fail -o "$temp_file" "$url"; then
    msg_err "Falló la descarga"
    rm -f "$temp_file"
    return 1
  fi

  if [[ ! -s "$temp_file" ]]; then
    msg_err "El archivo descargado está vacío"
    rm -f "$temp_file"
    return 1
  fi

  mkdir -p "$bin_dir"

  # Limpiar instalación previa y extraer
  rm -rf "$install_dir"
  mkdir -p "$install_dir"

  msg "Extrayendo archivos..."
  if ! tar -xzf "$temp_file" -C "$install_dir" --strip-components=1 2>/dev/null; then
    msg_err "Falló la extracción del tarball"
    rm -f "$temp_file"
    return 1
  fi

  rm -f "$temp_file"

  # Crear symlink al ejecutable
  if [[ -n "${EXEC_NAME:-}" ]]; then
    local exec_path
    exec_path=$(_tarball_exec_path "$install_dir" "$EXEC_NAME")
    if [[ -f "$exec_path" ]]; then
      chmod +x "$exec_path"
      ln -sf "$exec_path" "$bin_dir/$EXEC_NAME"
      msg_ok "Enlace creado: $bin_dir/$EXEC_NAME"
    else
      msg_warn "Ejecutable no encontrado en: $exec_path"
    fi
  fi

  msg_ok "Paquete instalado correctamente"
}

# Verifica si una app tarball está instalada
tarball_is_installed() {
  local install_dir="$1"
  local exec_name="$2"
  local exec_path
  exec_path=$(_tarball_exec_path "$install_dir" "$exec_name")
  [[ -d "$install_dir" ]] && [[ -f "$exec_path" ]]
}

# Obtiene la versión de una app tarball
tarball_get_version() {
  local install_dir="$1"
  local exec_name="$2"
  local exec_path
  exec_path=$(_tarball_exec_path "$install_dir" "$exec_name")

  if [[ -f "$exec_path" ]]; then
    local version
    version=$("$exec_path" --version 2>/dev/null | head -1)
    if [[ -n "$version" ]]; then
      echo "$version"
      return 0
    fi
  fi
  echo "desconocida"
  return 1
}

# Desinstala una app tarball
tarball_remove() {
  local install_dir="$1"
  local exec_name="$2"
  local bin_dir="${3:-$HOME/.local/bin}"

  rm -rf "$install_dir"
  rm -f "$bin_dir/$exec_name"
  msg_ok "Archivos eliminados"
}
