# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Gestor de aplicaciones de escritorio para Linux (RPM/Fedora). Descarga, instala, actualiza y desinstala apps vía menú interactivo o CLI directa.

## Comandos

```bash
# Menú interactivo principal
./manager.sh

# CLI directa por app
./manager.sh <app> install    # Instalar
./manager.sh <app> update     # Actualizar
./manager.sh <app> version    # Ver versión instalada
./manager.sh <app> remove     # Desinstalar
./manager.sh <app>            # Menú de acciones para esa app

# Operaciones masivas
./manager.sh all install      # Instalar todas
./manager.sh all update       # Actualizar todas
./manager.sh summary          # Resumen de estado

# Atajo de instalación rápida (legacy)
./install-all.sh [cursor|warp|vscode|all]

# Corregir permisos
./setup-permissions.sh
```

## Arquitectura

Dos capas: **librería compartida** (`lib/`) y **configuraciones de app** (`apps/`).

### lib/ — Librería compartida

- **common.sh** — Colores, funciones de logging (`msg`, `msg_ok`, `msg_err`, `msg_warn`), constantes globales (`ICON_DIR`, `DESKTOP_DIR`).
- **menu.sh** — `show_menu` (menú numerado interactivo, devuelve selección en `$MENU_SELECTION`), `confirm` (prompt s/N).
- **download.sh** — `resolve_download_url` (sigue redirecciones curl), `download_file`, `download_to_temp`, `download_appimage`.
- **rpm.sh** — Gestión RPM: `rpm_is_installed`, `rpm_get_version`, `rpm_install_file`, `rpm_update_file`, `rpm_remove`, `rpm_install_from_url`. Detecta automáticamente dnf vs rpm.
- **desktop.sh** — `install_icon`, `create_desktop_entry`, `remove_desktop_entry`, `setup_directories`.

### apps/ — Configuraciones de app

Cada archivo define variables: `APP_NAME`, `PACKAGE_NAME`, `DOWNLOAD_URL`, `ICON_URL`, `ICON_NAME`, `DESKTOP_FILE`, `CATEGORIES`, `EXEC_NAME`.

### Flujo

`manager.sh` → descubre `apps/*.sh` → carga config → usa `lib/rpm.sh` para instalar/actualizar/desinstalar + `lib/desktop.sh` para accesos directos.

### Agregar una nueva aplicación

1. Crear `apps/nueva-app.sh` con las variables de configuración (ver `apps/vscode.sh` como ejemplo).
2. Listo — `manager.sh` la descubre automáticamente.

### Código legacy

Los directorios `Cursor/` y `Warp/` contienen el sistema anterior con `install.sh` y `lib/` propias por app. `install-all.sh` ahora delega a `manager.sh`.

## Notas

- El directorio `bin/` (gitignored) almacena AppImages y binarios descargados.
- Todos los mensajes de usuario están en español.
- La instalación RPM requiere `sudo`.
