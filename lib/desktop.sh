#!/bin/bash

setup_directories() {
  mkdir -p "$ICON_DIR" "$DESKTOP_DIR"
}

install_icon() {
  local icon_url="$1"
  local icon_name="$2"

  msg "Descargando ícono..."
  if ! curl -L --progress-bar --fail -o "$ICON_DIR/$icon_name" "$icon_url"; then
    msg_err "Falló la descarga del ícono"
    return 1
  fi
  msg_ok "Ícono instalado"
}

create_desktop_entry() {
  local desktop_file="$1"
  local app_name="$2"
  local comment="$3"
  local exec_path="$4"
  local icon_name="$5"
  local categories="$6"

  msg "Creando acceso directo..."
  cat > "$DESKTOP_DIR/$desktop_file" <<EOF
[Desktop Entry]
Name=$app_name
Comment=$comment
Exec=$exec_path
Icon=$ICON_DIR/$icon_name
Terminal=false
Type=Application
Categories=$categories
EOF

  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  msg_ok "Acceso directo creado"
}

remove_desktop_entry() {
  local desktop_file="$1"
  local icon_name="$2"

  rm -f "$DESKTOP_DIR/$desktop_file"
  rm -f "$ICON_DIR/$icon_name"
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  msg_ok "Acceso directo eliminado"
}
