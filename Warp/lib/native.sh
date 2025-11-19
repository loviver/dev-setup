#!/bin/bash

download_native() {
  local url="$1"
  local temp_file
  local final_url
  local file_type
  
  echo "Resolviendo URL final..."
  if ! final_url=$(curl -Ls -o /dev/null -w "%{url_effective}" "$url" 2>/dev/null); then
    final_url="$url"
  fi
  
  echo "URL final: $final_url"
  
  temp_file=$(mktemp)
  
  echo "Descargando desde $final_url"
  echo "Guardando temporalmente en: $temp_file"
  
  if ! curl -L --progress-bar --fail -o "$temp_file" "$final_url"; then
    echo "Error: falló la descarga"
    rm -f "$temp_file"
    return 1
  fi
  
  if [[ ! -s "$temp_file" ]]; then
    echo "Error: el archivo descargado está vacío"
    rm -f "$temp_file"
    return 1
  fi
  
  local file_header
  file_header=$(file "$temp_file" 2>/dev/null || head -c 4 "$temp_file" | od -An -tx1 | tr -d ' \n')
  
  if [[ "$file_header" == *"RPM"* ]] || [[ "$file_header" == *"edab"* ]] || [[ "$final_url" == *.rpm ]]; then
    file_type="rpm"
    local rpm_file="${temp_file}.rpm"
    mv "$temp_file" "$rpm_file"
    temp_file="$rpm_file"
    echo "Archivo RPM detectado"
  elif [[ "$file_header" == *"Debian"* ]] || [[ "$final_url" == *.deb ]]; then
    file_type="deb"
    local deb_file="${temp_file}.deb"
    mv "$temp_file" "$deb_file"
    temp_file="$deb_file"
    echo "Archivo DEB detectado"
  else
    echo "Advertencia: tipo de archivo no reconocido. Verificando contenido..."
    if head -c 100 "$temp_file" | grep -q "RPM"; then
      file_type="rpm"
      local rpm_file="${temp_file}.rpm"
      mv "$temp_file" "$rpm_file"
      temp_file="$rpm_file"
      echo "Archivo RPM detectado por contenido"
    elif head -c 100 "$temp_file" | grep -q "html\|HTML"; then
      echo "Error: la URL devolvió HTML en lugar de un paquete"
      echo "Contenido recibido:"
      head -n 5 "$temp_file"
      rm -f "$temp_file"
      return 1
    else
      echo "Error: formato de archivo desconocido"
      echo "Tipo detectado: $(file "$temp_file" 2>/dev/null || echo 'desconocido')"
      rm -f "$temp_file"
      return 1
    fi
  fi
  
  if [[ "$file_type" == "rpm" ]]; then
    echo "Instalando paquete RPM..."
    
    if command -v rpm >/dev/null 2>&1; then
      local rpm_output
      rpm_output=$(sudo rpm -i "$temp_file" 2>&1)
      local rpm_exit=$?
      
      if [[ $rpm_exit -ne 0 ]]; then
        if echo "$rpm_output" | grep -q "already installed"; then
          echo "El paquete ya está instalado. Actualizando..."
          rpm_output=$(sudo rpm -U "$temp_file" 2>&1)
          rpm_exit=$?
        fi
        
        if [[ $rpm_exit -ne 0 ]]; then
          echo "Error: falló la instalación del paquete RPM"
          echo "Salida de rpm:"
          echo "$rpm_output"
          rm -f "$temp_file"
          return 1
        fi
      fi
    elif command -v dnf >/dev/null 2>&1; then
      local dnf_output
      dnf_output=$(sudo dnf install -y "$temp_file" 2>&1)
      local dnf_exit=$?
      
      if [[ $dnf_exit -ne 0 ]]; then
        echo "Error: falló la instalación del paquete RPM"
        echo "Salida de dnf:"
        echo "$dnf_output"
        rm -f "$temp_file"
        return 1
      fi
    else
      echo "Error: no se encontró rpm ni dnf. Instala uno de ellos primero."
      rm -f "$temp_file"
      return 1
    fi
  elif [[ "$file_type" == "deb" ]]; then
    echo "Instalando paquete DEB..."
    
    if command -v dpkg >/dev/null 2>&1; then
      local dpkg_output
      dpkg_output=$(sudo dpkg -i "$temp_file" 2>&1)
      local dpkg_exit=$?
      
      if [[ $dpkg_exit -ne 0 ]]; then
        echo "Resolviendo dependencias..."
        sudo apt-get install -f -y >/dev/null 2>&1
      fi
    elif command -v rpm >/dev/null 2>&1; then
      echo "Convirtiendo .deb a .rpm..."
      if command -v alien >/dev/null 2>&1; then
        if alien -r "$temp_file" >/dev/null 2>&1; then
          sudo rpm -i "${temp_file%.deb}-*.rpm" 2>/dev/null
          rm -f "${temp_file%.deb}-*.rpm"
        else
          echo "Error: falló la conversión"
          rm -f "$temp_file"
          return 1
        fi
      else
        echo "Error: alien no está disponible. Instala alien o usa dpkg."
        rm -f "$temp_file"
        return 1
      fi
    else
      echo "Error: no se encontró dpkg ni rpm. Instala uno de ellos primero."
      rm -f "$temp_file"
      return 1
    fi
  fi
  
  rm -f "$temp_file"
  
  echo "Versión nativa instalada correctamente"
}

get_executable_path() {
  if command -v warp-terminal >/dev/null 2>&1; then
    echo "warp-terminal"
  else
    echo "/usr/bin/warp-terminal"
  fi
}

cleanup_appimage() {
  local install_dir="$1"
  local app_name="$2"
  
  echo "Buscando AppImage anterior para eliminar..."
  
  if find "$install_dir" -maxdepth 1 -name "*${app_name}*.AppImage" -type f 2>/dev/null | grep -q .; then
    echo "Eliminando AppImage anterior..."
    find "$install_dir" -maxdepth 1 -name "*${app_name}*.AppImage" -type f -delete
    echo "AppImage eliminado"
  else
    echo "No se encontró AppImage anterior"
  fi
}

