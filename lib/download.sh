#!/bin/bash

resolve_download_url() {
  local url="$1"
  msg "Resolviendo URL final..."

  local final_url curl_stderr_file
  curl_stderr_file=$(mktemp)
  final_url=$(curl -gLs -o /dev/null -w "%{url_effective}" "$url" 2>"$curl_stderr_file")
  local curl_exit=$?
  local curl_error
  curl_error=$(cat "$curl_stderr_file")
  rm -f "$curl_stderr_file"

  if [[ $curl_exit -ne 0 ]]; then
    msg_err "No se pudo resolver la URL final."
    [[ -n "$curl_error" ]] && msg_err "curl: $curl_error"
    return 1
  fi

  if [[ -z "$final_url" ]] || [[ ! "$final_url" =~ ^https?:// ]]; then
    msg_err "URL resuelta inválida: $final_url"
    return 1
  fi

  msg "URL resuelta: $final_url"
  echo "$final_url"
}

download_file() {
  local url="$1"
  local dest="$2"

  msg "Descargando desde $url"
  msg "Guardando en: $dest"

  if ! curl -gL --progress-bar --fail -o "$dest" "$url"; then
    msg_err "Falló la descarga"
    rm -f "$dest"
    return 1
  fi

  if [[ ! -s "$dest" ]]; then
    msg_err "El archivo descargado está vacío"
    rm -f "$dest"
    return 1
  fi
}

download_to_temp() {
  local url="$1"
  local temp_file
  temp_file=$(mktemp)

  if ! download_file "$url" "$temp_file"; then
    return 1
  fi

  echo "$temp_file"
}

validate_appimage() {
  local filename="$1"
  if [[ "$filename" != *.AppImage ]]; then
    msg_err "El archivo recibido no es AppImage: $filename"
    return 1
  fi
}

download_appimage() {
  local url="$1"
  local install_dir="$2"
  local filename="$3"

  if ! download_file "$url" "$install_dir/$filename"; then
    return 1
  fi

  chmod +x "$install_dir/$filename"
  msg_ok "AppImage descargada: $install_dir/$filename"
}
