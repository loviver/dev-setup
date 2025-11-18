#!/bin/bash

resolve_download_url() {
  local url="$1"
  echo "Resolviendo URL final..." >&2
  
  local final_url
  local curl_stderr_file
  
  curl_stderr_file=$(mktemp)
  final_url=$(curl -Ls -o /dev/null -w "%{url_effective}" "$url" 2>"$curl_stderr_file")
  local curl_exit=$?
  local curl_error=$(cat "$curl_stderr_file")
  rm -f "$curl_stderr_file"
  
  if [[ $curl_exit -ne 0 ]]; then
    echo "Error: no se pudo resolver la URL final." >&2
    echo "URL intentada: $url" >&2
    if [[ -n "$curl_error" ]]; then
      echo "Error de curl: $curl_error" >&2
    fi
    return 1
  fi
  
  if [[ -z "$final_url" ]] || [[ "$final_url" == *"curl:"* ]] || [[ ! "$final_url" =~ ^https?:// ]]; then
    echo "Error: URL resuelta inválida." >&2
    echo "URL intentada: $url" >&2
    echo "Respuesta recibida: $final_url" >&2
    if [[ -n "$curl_error" ]]; then
      echo "Error de curl: $curl_error" >&2
    fi
    return 1
  fi
  
  echo "URL resuelta: $final_url" >&2
  echo "$final_url"
}

validate_appimage() {
  local filename="$1"
  
  if [[ "$filename" != *.AppImage ]]; then
    echo "Error: el archivo recibido no es AppImage. Nombre: $filename"
    return 1
  fi
  
  return 0
}

download_appimage() {
  local url="$1"
  local install_dir="$2"
  local filename="$3"
  
  echo "Descargando $filename desde $url"
  echo "Guardando en: $install_dir/$filename"
  
  if ! curl -L --progress-bar --fail -o "$install_dir/$filename" "$url"; then
    echo "Error: falló la descarga de $filename"
    return 1
  fi
  
  echo "Aplicando permisos de ejecución..."
  chmod +x "$install_dir/$filename"
  
  echo "AppImage descargada correctamente: $install_dir/$filename"
}
