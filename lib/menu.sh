#!/bin/bash

# Muestra un menú numerado y devuelve la selección en MENU_SELECTION
# Uso: show_menu "Título" "opcion1" "opcion2" ...
# La última opción siempre se trata como "salir/volver"
show_menu() {
  local title="$1"
  shift
  local options=("$@")
  local count=${#options[@]}

  echo ""
  separator
  msg_bold "  $title"
  separator
  echo ""

  for i in "${!options[@]}"; do
    local num=$((i + 1))
    if [[ $num -eq $count ]]; then
      echo -e "  ${RED}${num})${NC} ${options[$i]}"
    else
      echo -e "  ${CYAN}${num})${NC} ${options[$i]}"
    fi
  done

  echo ""
  while true; do
    read -rp "$(echo -e "${BOLD}Selecciona una opción [1-${count}]: ${NC}")" MENU_SELECTION
    if [[ "$MENU_SELECTION" =~ ^[0-9]+$ ]] && (( MENU_SELECTION >= 1 && MENU_SELECTION <= count )); then
      return 0
    fi
    msg_err "Opción inválida"
  done
}

# Pide confirmación y/n
confirm() {
  local prompt="${1:-¿Continuar?}"
  read -rp "$(echo -e "${YELLOW}${prompt} [s/N]: ${NC}")" resp
  [[ "$resp" =~ ^[sS]$ ]]
}
