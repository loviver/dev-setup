#!/bin/bash

# Detecta el gestor de paquetes RPM disponible
rpm_detect_manager() {
  if command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v rpm >/dev/null 2>&1; then
    echo "rpm"
  else
    echo ""
  fi
}

# Verifica si un paquete RPM está instalado
# Uso: rpm_is_installed "code"
rpm_is_installed() {
  local package="$1"
  rpm -q "$package" &>/dev/null
}

# Obtiene la versión instalada de un paquete
rpm_get_version() {
  local package="$1"
  if rpm_is_installed "$package"; then
    rpm -q --queryformat '%{VERSION}-%{RELEASE}' "$package" 2>/dev/null
  else
    echo "no instalado"
    return 1
  fi
}

# Instala un archivo RPM
rpm_install_file() {
  local rpm_file="$1"
  local manager
  manager=$(rpm_detect_manager)

  if [[ -z "$manager" ]]; then
    msg_err "No se encontró rpm ni dnf"
    return 1
  fi

  msg "Instalando con $manager..."

  if [[ "$manager" == "dnf" ]]; then
    if ! sudo dnf install -y "$rpm_file" 2>&1; then
      msg_err "Falló la instalación con dnf"
      return 1
    fi
  else
    local output
    output=$(sudo rpm -i "$rpm_file" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
      if echo "$output" | grep -q "already installed"; then
        msg_warn "Ya instalado. Actualizando..."
        output=$(sudo rpm -U "$rpm_file" 2>&1)
        exit_code=$?
      fi
      if [[ $exit_code -ne 0 ]]; then
        msg_err "Falló la instalación RPM"
        echo "$output"
        return 1
      fi
    fi
  fi

  msg_ok "Paquete instalado correctamente"
}

# Actualiza un paquete RPM desde archivo
rpm_update_file() {
  local rpm_file="$1"
  local manager
  manager=$(rpm_detect_manager)

  if [[ -z "$manager" ]]; then
    msg_err "No se encontró rpm ni dnf"
    return 1
  fi

  msg "Actualizando con $manager..."

  if [[ "$manager" == "dnf" ]]; then
    if ! sudo dnf upgrade -y "$rpm_file" 2>&1; then
      msg_err "Falló la actualización con dnf"
      return 1
    fi
  else
    if ! sudo rpm -U "$rpm_file" 2>&1; then
      msg_err "Falló la actualización con rpm"
      return 1
    fi
  fi

  msg_ok "Paquete actualizado correctamente"
}

# Desinstala un paquete por nombre
rpm_remove() {
  local package="$1"
  local manager
  manager=$(rpm_detect_manager)

  if ! rpm_is_installed "$package"; then
    msg_warn "$package no está instalado"
    return 0
  fi

  if [[ "$manager" == "dnf" ]]; then
    sudo dnf remove -y "$package"
  else
    sudo rpm -e "$package"
  fi
}

# Descarga e instala/actualiza un RPM desde URL
# Uso: rpm_install_from_url "https://..." ["install"|"update"]
rpm_install_from_url() {
  local url="$1"
  local action="${2:-install}"

  local final_url
  if ! final_url=$(resolve_download_url "$url"); then
    return 1
  fi

  local temp_file
  if ! temp_file=$(download_to_temp "$final_url"); then
    return 1
  fi

  # Verificar que es RPM
  local file_info
  file_info=$(file "$temp_file" 2>/dev/null || echo "")

  if [[ "$file_info" != *"RPM"* ]] && [[ "$final_url" != *.rpm ]]; then
    if head -c 100 "$temp_file" | grep -qi "html"; then
      msg_err "La URL devolvió HTML en lugar de un paquete RPM"
      rm -f "$temp_file"
      return 1
    fi
  fi

  local rpm_file="${temp_file}.rpm"
  mv "$temp_file" "$rpm_file"

  local result
  if [[ "$action" == "update" ]]; then
    rpm_update_file "$rpm_file"
    result=$?
  else
    rpm_install_file "$rpm_file"
    result=$?
  fi

  rm -f "$rpm_file"
  return $result
}
