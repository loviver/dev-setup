#!/bin/bash

setup_directories() {
  local install_dir="$1"
  local icon_dir="$2"
  local desktop_dir="$3"
  
  mkdir -p "$install_dir"
  mkdir -p "$icon_dir"
  mkdir -p "$desktop_dir"
}
