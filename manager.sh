#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cargar librerías compartidas
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/menu.sh"
source "$SCRIPT_DIR/lib/download.sh"
source "$SCRIPT_DIR/lib/rpm.sh"
source "$SCRIPT_DIR/lib/desktop.sh"

# Descubre apps disponibles en apps/
discover_apps() {
  local apps=()
  for config in "$SCRIPT_DIR/apps/"*.sh; do
    [[ -f "$config" ]] && apps+=("$config")
  done
  echo "${apps[@]}"
}

# Carga la config de una app
load_app_config() {
  local config_file="$1"
  # Limpiar variables previas
  unset APP_NAME APP_COMMENT PACKAGE_NAME DOWNLOAD_URL
  unset ICON_URL ICON_NAME DESKTOP_FILE CATEGORIES EXEC_NAME
  source "$config_file"
}

# Muestra el estado de una app
show_app_status() {
  if rpm_is_installed "$PACKAGE_NAME"; then
    local version
    version=$(rpm_get_version "$PACKAGE_NAME")
    echo -e "  Estado: ${GREEN}instalado${NC} (${version})"
  else
    echo -e "  Estado: ${YELLOW}no instalado${NC}"
  fi
}

# Acciones sobre una app individual
app_actions() {
  local config_file="$1"

  while true; do
    load_app_config "$config_file"

    echo ""
    separator
    msg_bold "  $APP_NAME"
    separator
    show_app_status
    echo ""

    local is_installed=false
    rpm_is_installed "$PACKAGE_NAME" && is_installed=true

    if $is_installed; then
      show_menu "Acciones" \
        "Actualizar (reinstalar última versión)" \
        "Verificar versión instalada" \
        "Reparar acceso directo" \
        "Desinstalar" \
        "Volver"

      case $MENU_SELECTION in
        1) action_update "$config_file" ;;
        2) action_version ;;
        3) action_repair_desktop ;;
        4) action_remove ;;
        5) return ;;
      esac
    else
      show_menu "Acciones" \
        "Instalar" \
        "Volver"

      case $MENU_SELECTION in
        1) action_install "$config_file" ;;
        2) return ;;
      esac
    fi

    echo ""
    read -rp "$(echo -e "${CYAN}Presiona Enter para continuar...${NC}")"
  done
}

action_install() {
  local config_file="$1"
  load_app_config "$config_file"

  echo ""
  msg "Instalando $APP_NAME..."
  setup_directories

  if ! rpm_install_from_url "$DOWNLOAD_URL" "install"; then
    msg_err "Falló la instalación de $APP_NAME"
    return 1
  fi

  install_icon "$ICON_URL" "$ICON_NAME"
  local exec_path
  exec_path=$(command -v "$EXEC_NAME" 2>/dev/null || echo "/usr/bin/$EXEC_NAME")
  create_desktop_entry "$DESKTOP_FILE" "$APP_NAME" "$APP_COMMENT" "$exec_path" "$ICON_NAME" "$CATEGORIES"

  echo ""
  msg_ok "$APP_NAME instalado correctamente"
}

action_update() {
  local config_file="$1"
  load_app_config "$config_file"

  echo ""
  local current_version
  current_version=$(rpm_get_version "$PACKAGE_NAME")
  msg "Versión actual: $current_version"

  if ! confirm "¿Descargar e instalar la última versión?"; then
    return
  fi

  msg "Actualizando $APP_NAME..."

  if ! rpm_install_from_url "$DOWNLOAD_URL" "update"; then
    msg_err "Falló la actualización de $APP_NAME"
    return 1
  fi

  local new_version
  new_version=$(rpm_get_version "$PACKAGE_NAME")
  msg_ok "Actualizado: $current_version → $new_version"
}

action_version() {
  echo ""
  if rpm_is_installed "$PACKAGE_NAME"; then
    local version
    version=$(rpm_get_version "$PACKAGE_NAME")
    msg "Paquete: $PACKAGE_NAME"
    msg "Versión: $version"
    echo ""
    msg "Detalles del paquete:"
    rpm -qi "$PACKAGE_NAME" 2>/dev/null | grep -E "^(Name|Version|Release|Install Date|Size|Summary)" | while read -r line; do
      echo "  $line"
    done
  else
    msg_warn "$PACKAGE_NAME no está instalado"
  fi
}

action_repair_desktop() {
  echo ""
  msg "Reparando acceso directo de $APP_NAME..."
  setup_directories
  install_icon "$ICON_URL" "$ICON_NAME"
  local exec_path
  exec_path=$(command -v "$EXEC_NAME" 2>/dev/null || echo "/usr/bin/$EXEC_NAME")
  create_desktop_entry "$DESKTOP_FILE" "$APP_NAME" "$APP_COMMENT" "$exec_path" "$ICON_NAME" "$CATEGORIES"
  msg_ok "Acceso directo reparado"
}

action_remove() {
  echo ""
  if ! confirm "¿Desinstalar $APP_NAME?"; then
    return
  fi

  msg "Desinstalando $APP_NAME..."
  rpm_remove "$PACKAGE_NAME"
  remove_desktop_entry "$DESKTOP_FILE" "$ICON_NAME"
  msg_ok "$APP_NAME desinstalado"
}

# Instalar/actualizar todas las apps
action_batch() {
  local action="$1"
  local configs
  read -ra configs <<< "$(discover_apps)"

  for config in "${configs[@]}"; do
    load_app_config "$config"
    echo ""
    separator
    msg_bold "  $APP_NAME"
    separator

    if [[ "$action" == "install" ]]; then
      if rpm_is_installed "$PACKAGE_NAME"; then
        msg "Ya instalado, saltando..."
      else
        action_install "$config"
      fi
    elif [[ "$action" == "update" ]]; then
      if rpm_is_installed "$PACKAGE_NAME"; then
        msg "Actualizando..."
        rpm_install_from_url "$DOWNLOAD_URL" "update" || msg_err "Falló la actualización"
      else
        msg_warn "No instalado, saltando..."
      fi
    fi
  done

  echo ""
  msg_ok "Operación completada"
}

# Mostrar resumen de todas las apps
show_summary() {
  local configs
  read -ra configs <<< "$(discover_apps)"

  echo ""
  separator
  msg_bold "  Estado de aplicaciones"
  separator
  echo ""

  for config in "${configs[@]}"; do
    load_app_config "$config"
    if rpm_is_installed "$PACKAGE_NAME"; then
      local version
      version=$(rpm_get_version "$PACKAGE_NAME")
      echo -e "  ${GREEN}●${NC} $APP_NAME ${CYAN}($version)${NC}"
    else
      echo -e "  ${RED}○${NC} $APP_NAME ${YELLOW}(no instalado)${NC}"
    fi
  done
  echo ""
}

# Menú principal
main_menu() {
  while true; do
    # Construir lista de apps dinámicamente
    local configs
    read -ra configs <<< "$(discover_apps)"
    local menu_items=()

    for config in "${configs[@]}"; do
      load_app_config "$config"
      local status=""
      if rpm_is_installed "$PACKAGE_NAME"; then
        status=" ${GREEN}[instalado]${NC}"
      fi
      menu_items+=("$(echo -e "$APP_NAME$status")")
    done

    menu_items+=("─── Acciones masivas ───")
    menu_items+=("Instalar todas")
    menu_items+=("Actualizar todas")
    menu_items+=("Ver resumen")
    menu_items+=("Salir")

    show_menu "Gestor de Aplicaciones" "${menu_items[@]}"

    local app_count=${#configs[@]}
    local separator_idx=$((app_count + 1))
    local install_all_idx=$((app_count + 2))
    local update_all_idx=$((app_count + 3))
    local summary_idx=$((app_count + 4))
    local exit_idx=$((app_count + 5))

    if (( MENU_SELECTION >= 1 && MENU_SELECTION <= app_count )); then
      app_actions "${configs[$((MENU_SELECTION - 1))]}"
    elif (( MENU_SELECTION == separator_idx )); then
      msg_warn "Selecciona una opción válida"
    elif (( MENU_SELECTION == install_all_idx )); then
      action_batch "install"
      read -rp "$(echo -e "${CYAN}Presiona Enter para continuar...${NC}")"
    elif (( MENU_SELECTION == update_all_idx )); then
      if confirm "¿Actualizar todas las aplicaciones instaladas?"; then
        action_batch "update"
      fi
      read -rp "$(echo -e "${CYAN}Presiona Enter para continuar...${NC}")"
    elif (( MENU_SELECTION == summary_idx )); then
      show_summary
      read -rp "$(echo -e "${CYAN}Presiona Enter para continuar...${NC}")"
    elif (( MENU_SELECTION == exit_idx )); then
      echo ""
      msg "Hasta luego"
      exit 0
    fi
  done
}

# Soporte para uso directo: ./manager.sh [app] [acción]
if [[ $# -ge 1 ]]; then
  case "$1" in
    -h|--help)
      cat <<EOF
Gestor de Aplicaciones

Uso: $(basename "$0") [OPCIONES]

Sin argumentos:  Menú interactivo
  <app>            Menú de acciones para esa app
  <app> install    Instalar app directamente
  <app> update     Actualizar app directamente
  <app> remove     Desinstalar app
  <app> version    Mostrar versión instalada
  all install      Instalar todas
  all update       Actualizar todas
  summary          Mostrar resumen
  -h, --help       Mostrar esta ayuda

Apps disponibles:
EOF
      for config in "$SCRIPT_DIR/apps/"*.sh; do
        [[ -f "$config" ]] || continue
        local_name=$(basename "$config" .sh)
        source "$config"
        echo "  $local_name  ($APP_NAME)"
      done
      exit 0
      ;;
    summary)
      show_summary
      exit 0
      ;;
    all)
      action="${2:-install}"
      action_batch "$action"
      exit 0
      ;;
    *)
      config_file="$SCRIPT_DIR/apps/$1.sh"
      if [[ ! -f "$config_file" ]]; then
        msg_err "App no encontrada: $1"
        msg "Apps disponibles:"
        for config in "$SCRIPT_DIR/apps/"*.sh; do
          echo "  $(basename "$config" .sh)"
        done
        exit 1
      fi

      action="${2:-}"
      load_app_config "$config_file"

      case "$action" in
        install) action_install "$config_file" ;;
        update)  action_update "$config_file" ;;
        remove)  action_remove ;;
        version) action_version ;;
        "")      app_actions "$config_file" ;;
        *)
          msg_err "Acción desconocida: $action"
          exit 1
          ;;
      esac
      exit 0
      ;;
  esac
else
  main_menu
fi
