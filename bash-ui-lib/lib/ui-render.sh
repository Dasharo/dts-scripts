#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# ui-render.sh - Rendering functions for bash-ui-lib

# Prevent multiple sourcing
if [[ -n "${_UI_RENDER_SOURCED}" ]]; then
  return 0
fi
_UI_RENDER_SOURCED=1

# Source dependencies
UI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${UI_LIB_DIR}/ui-colors.sh"
source "${UI_LIB_DIR}/ui-utils.sh"

# Menu item storage
declare -ga UI_MENU_ITEMS_KEYS=()
declare -gA UI_MENU_ITEMS_TEXT=()
declare -gA UI_MENU_ITEMS_HANDLER=()
declare -gA UI_MENU_ITEMS_CONDITION=()

# Footer action storage
declare -ga UI_FOOTER_ACTIONS_KEYS=()
declare -gA UI_FOOTER_ACTIONS_TEXT=()
declare -gA UI_FOOTER_ACTIONS_HANDLER=()
declare -gA UI_FOOTER_ACTIONS_CONDITION=()

# Header/Footer callback functions
UI_HEADER_CALLBACK=""
UI_FOOTER_CALLBACK=""
UI_INFO_SECTION_CALLBACK=""

# Default separator character and width
UI_SEPARATOR_CHAR="*"
UI_SEPARATOR_WIDTH=57

# ui_add_menu_item <key> <text> <handler> [condition_function]
# Add a menu item
# condition_function: optional function that returns 0 to show item, 1 to hide
ui_add_menu_item() {
  local key="$1"
  local text="$2"
  local handler="$3"
  local condition="${4:-}"

  if [[ -z "$key" || -z "$text" || -z "$handler" ]]; then
    ui_print_error "ui_add_menu_item: key, text, and handler are required"
    return 1
  fi

  # Check if key already exists
  if [[ " ${UI_MENU_ITEMS_KEYS[*]} " =~ " ${key} " ]]; then
    ui_print_warning "ui_add_menu_item: key '$key' already exists, overwriting"
  else
    UI_MENU_ITEMS_KEYS+=("$key")
  fi

  UI_MENU_ITEMS_TEXT["$key"]="$text"
  UI_MENU_ITEMS_HANDLER["$key"]="$handler"
  UI_MENU_ITEMS_CONDITION["$key"]="$condition"
}

# ui_remove_menu_item <key>
# Remove a menu item
ui_remove_menu_item() {
  local key="$1"
  local new_keys=()

  for k in "${UI_MENU_ITEMS_KEYS[@]}"; do
    if [[ "$k" != "$key" ]]; then
      new_keys+=("$k")
    fi
  done

  UI_MENU_ITEMS_KEYS=("${new_keys[@]}")
  unset "UI_MENU_ITEMS_TEXT[$key]"
  unset "UI_MENU_ITEMS_HANDLER[$key]"
  unset "UI_MENU_ITEMS_CONDITION[$key]"
}

# ui_clear_menu_items
# Clear all menu items
ui_clear_menu_items() {
  UI_MENU_ITEMS_KEYS=()
  UI_MENU_ITEMS_TEXT=()
  UI_MENU_ITEMS_HANDLER=()
  UI_MENU_ITEMS_CONDITION=()
}

# ui_add_footer_action <key> <text> <handler> [condition_function]
# Add a footer action
ui_add_footer_action() {
  local key="$1"
  local text="$2"
  local handler="$3"
  local condition="${4:-}"

  if [[ -z "$key" || -z "$text" || -z "$handler" ]]; then
    ui_print_error "ui_add_footer_action: key, text, and handler are required"
    return 1
  fi

  # Check if key already exists
  if [[ " ${UI_FOOTER_ACTIONS_KEYS[*]} " =~ " ${key} " ]]; then
    ui_print_warning "ui_add_footer_action: key '$key' already exists, overwriting"
  else
    UI_FOOTER_ACTIONS_KEYS+=("$key")
  fi

  UI_FOOTER_ACTIONS_TEXT["$key"]="$text"
  UI_FOOTER_ACTIONS_HANDLER["$key"]="$handler"
  UI_FOOTER_ACTIONS_CONDITION["$key"]="$condition"
}

# ui_remove_footer_action <key>
# Remove a footer action
ui_remove_footer_action() {
  local key="$1"
  local new_keys=()

  for k in "${UI_FOOTER_ACTIONS_KEYS[@]}"; do
    if [[ "$k" != "$key" ]]; then
      new_keys+=("$k")
    fi
  done

  UI_FOOTER_ACTIONS_KEYS=("${new_keys[@]}")
  unset "UI_FOOTER_ACTIONS_TEXT[$key]"
  unset "UI_FOOTER_ACTIONS_HANDLER[$key]"
  unset "UI_FOOTER_ACTIONS_CONDITION[$key]"
}

# ui_clear_footer_actions
# Clear all footer actions
ui_clear_footer_actions() {
  UI_FOOTER_ACTIONS_KEYS=()
  UI_FOOTER_ACTIONS_TEXT=()
  UI_FOOTER_ACTIONS_HANDLER=()
  UI_FOOTER_ACTIONS_CONDITION=()
}

# ui_set_header_callback <function_name>
# Set custom header rendering function
ui_set_header_callback() {
  UI_HEADER_CALLBACK="$1"
}

# ui_set_footer_callback <function_name>
# Set custom footer rendering function
ui_set_footer_callback() {
  UI_FOOTER_CALLBACK="$1"
}

# ui_set_info_section_callback <function_name>
# Set custom info section rendering function (displayed between header and menu)
ui_set_info_section_callback() {
  UI_INFO_SECTION_CALLBACK="$1"
}

# ui_render_separator
# Render separator line
ui_render_separator() {
  echo -ne "${UI_THEME[BORDER]}"
  printf '%*s\n' "$UI_SEPARATOR_WIDTH" '' | tr ' ' "$UI_SEPARATOR_CHAR"
  echo -ne "${UI_COLORS[NORMAL]}"
}

# ui_render_default_header <title> [subtitle]
# Render default header
ui_render_default_header() {
  local title="$1"
  local subtitle="${2:-}"

  echo -e "${UI_COLORS[NORMAL]}"
  ui_render_separator
  echo -e "${UI_COLORS[BOLD]}  $title${UI_COLORS[NORMAL]}"
  if [[ -n "$subtitle" ]]; then
    echo -e "  $subtitle"
  fi
  ui_render_separator
}

# ui_render_header
# Render header (uses callback if set, otherwise default)
ui_render_header() {
  if [[ -n "$UI_HEADER_CALLBACK" ]] && type -t "$UI_HEADER_CALLBACK" &>/dev/null; then
    "$UI_HEADER_CALLBACK"
  else
    ui_render_default_header "Menu"
  fi
}

# ui_render_info_section
# Render info section (uses callback if set)
ui_render_info_section() {
  if [[ -n "$UI_INFO_SECTION_CALLBACK" ]] && type -t "$UI_INFO_SECTION_CALLBACK" &>/dev/null; then
    "$UI_INFO_SECTION_CALLBACK"
  fi
}

# ui_render_menu
# Render menu items
ui_render_menu() {
  local has_items=0

  for key in "${UI_MENU_ITEMS_KEYS[@]}"; do
    local condition="${UI_MENU_ITEMS_CONDITION[$key]}"

    # Check condition if set
    if [[ -n "$condition" ]] && type -t "$condition" &>/dev/null; then
      if ! "$condition"; then
        continue
      fi
    fi

    local text="${UI_MENU_ITEMS_TEXT[$key]}"
    echo -e "${UI_THEME[MENU_KEY]}     ${key})${UI_THEME[MENU_TEXT]} ${text}${UI_COLORS[NORMAL]}"
    has_items=1
  done

  if [[ $has_items -eq 0 ]]; then
    echo "  No menu items available."
  fi
}

# ui_render_default_footer
# Render default footer with actions
ui_render_default_footer() {
  ui_render_separator

  # Render footer actions
  local line=""
  local count=0
  for key in "${UI_FOOTER_ACTIONS_KEYS[@]}"; do
    local condition="${UI_FOOTER_ACTIONS_CONDITION[$key]}"

    # Check condition if set
    if [[ -n "$condition" ]] && type -t "$condition" &>/dev/null; then
      if ! "$condition"; then
        continue
      fi
    fi

    local text="${UI_FOOTER_ACTIONS_TEXT[$key]}"

    if [[ $count -gt 0 ]]; then
      line+="  "
    fi

    line+="${UI_THEME[FOOTER_KEY]}${key}${UI_COLORS[NORMAL]} to ${text}"
    count=$((count + 1))

    # Print line if it gets too long
    if [[ ${#line} -gt 50 ]]; then
      echo -e "$line"
      line=""
      count=0
    fi
  done

  # Print remaining actions
  if [[ -n "$line" ]]; then
    echo -e "$line"
  fi

  echo -ne "${UI_THEME[PROMPT]}\nEnter an option:${UI_COLORS[NORMAL]} "
}

# ui_render_footer
# Render footer (uses callback if set, otherwise default)
ui_render_footer() {
  if [[ -n "$UI_FOOTER_CALLBACK" ]] && type -t "$UI_FOOTER_CALLBACK" &>/dev/null; then
    "$UI_FOOTER_CALLBACK"
  else
    ui_render_default_footer
  fi
}

# ui_render_screen
# Render complete screen (header, info, menu, footer)
ui_render_screen() {
  ui_clear_screen
  ui_render_header
  ui_render_info_section
  ui_render_menu
  ui_render_footer
}

# ui_handle_menu_selection <key>
# Handle menu item selection
# Returns 0 if handled, 1 if not found
ui_handle_menu_selection() {
  local key="$1"

  # Check if key exists in menu items
  if [[ -n "${UI_MENU_ITEMS_HANDLER[$key]+isset}" ]]; then
    local condition="${UI_MENU_ITEMS_CONDITION[$key]}"

    # Check condition if set
    if [[ -n "$condition" ]] && type -t "$condition" &>/dev/null; then
      if ! "$condition"; then
        return 1
      fi
    fi

    local handler="${UI_MENU_ITEMS_HANDLER[$key]}"
    if type -t "$handler" &>/dev/null; then
      "$handler"
      return 0
    else
      ui_print_error "Handler function '$handler' not found for menu item '$key'"
      ui_pause
      return 1
    fi
  fi

  return 1
}

# ui_handle_footer_selection <key>
# Handle footer action selection
# Returns 0 if handled, 1 if not found
ui_handle_footer_selection() {
  local key="$1"

  # Check if key exists in footer actions
  if [[ -n "${UI_FOOTER_ACTIONS_HANDLER[$key]+isset}" ]]; then
    local condition="${UI_FOOTER_ACTIONS_CONDITION[$key]}"

    # Check condition if set
    if [[ -n "$condition" ]] && type -t "$condition" &>/dev/null; then
      if ! "$condition"; then
        return 1
      fi
    fi

    local handler="${UI_FOOTER_ACTIONS_HANDLER[$key]}"
    if type -t "$handler" &>/dev/null; then
      "$handler"
      return 0
    else
      ui_print_error "Handler function '$handler' not found for footer action '$key'"
      ui_pause
      return 1
    fi
  fi

  return 1
}
