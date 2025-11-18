#!/bin/bash

install_icon() {
  local icon_url="$1"
  local icon_dir="$2"
  local icon_name="$3"
  
  echo "Descargando ícono desde $icon_url"
  echo "Guardando en: $icon_dir/$icon_name"
  
  if ! curl -L --progress-bar --fail -o "$icon_dir/$icon_name" "$icon_url"; then
    echo "Error: falló la descarga del ícono"
    return 1
  fi
  
  echo "Ícono instalado correctamente"
}

create_desktop_entry() {
  local desktop_dir="$1"
  local desktop_file="$2"
  local app_name="$3"
  local comment="$4"
  local exec_path="$5"
  local icon_path="$6"
  local categories="$7"
  
  echo "Creando acceso directo..."
  
  cat > "$desktop_dir/$desktop_file" <<EOF
[Desktop Entry]
Name=$app_name
Comment=$comment
Exec=$exec_path
Icon=$icon_path
Terminal=false
Type=Application
Categories=$categories
EOF
}

update_desktop_database() {
  local desktop_dir="$1"
  update-desktop-database "$desktop_dir" 2>/dev/null || true
}
