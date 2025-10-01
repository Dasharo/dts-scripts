#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# ui-core.sh - Core UI engine and main loop for bash-ui-lib

# Prevent multiple sourcing
if [[ -n "${_UI_CORE_SOURCED}" ]]; then
  return 0
fi
_UI_CORE_SOURCED=1

# Source dependencies
UI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${UI_LIB_DIR}/ui-colors.sh"
source "${UI_LIB_DIR}/ui-utils.sh"
source "${UI_LIB_DIR}/ui-render.sh"

# Main loop control
UI_LOOP_RUNNING=0
UI_LOOP_EXIT_CODE=0

# Input mode: "single" or "line"
UI_INPUT_MODE="single"

# Pre/Post render callbacks
UI_PRE_RENDER_CALLBACK=""
UI_POST_RENDER_CALLBACK=""

# ui_init
# Initialize the UI library
ui_init() {
  # Ensure we're in an interactive terminal
  if ! ui_is_interactive; then
    ui_print_warning "Warning: Not running in an interactive terminal"
  fi

  # Get terminal size
  ui_get_terminal_size

  # Set up signal handlers
  trap ui_handle_sigint INT
  trap ui_handle_sigterm TERM
}

# ui_handle_sigint
# Handle SIGINT (Ctrl+C)
ui_handle_sigint() {
  # Ignore SIGINT in menu (prevent accidental exit)
  :
}

# ui_handle_sigterm
# Handle SIGTERM
ui_handle_sigterm() {
  # Ignore SIGTERM in menu
  :
}

# ui_set_input_mode <mode>
# Set input mode: "single" or "line"
ui_set_input_mode() {
  local mode="$1"
  if [[ "$mode" != "single" && "$mode" != "line" ]]; then
    ui_print_error "Invalid input mode: $mode (must be 'single' or 'line')"
    return 1
  fi
  UI_INPUT_MODE="$mode"
}

# ui_set_pre_render_callback <function>
# Set callback to run before rendering (e.g., for state updates)
ui_set_pre_render_callback() {
  UI_PRE_RENDER_CALLBACK="$1"
}

# ui_set_post_render_callback <function>
# Set callback to run after rendering
ui_set_post_render_callback() {
  UI_POST_RENDER_CALLBACK="$1"
}

# ui_read_input
# Read input based on current input mode
# Sets UI_INPUT variable
ui_read_input() {
  UI_INPUT=""

  if [[ "$UI_INPUT_MODE" == "single" ]]; then
    read -r -n 1 UI_INPUT
    echo
  else
    read -r UI_INPUT
  fi
}

# ui_process_input <input>
# Process user input and call appropriate handlers
# Returns 0 if input was handled, 1 otherwise
ui_process_input() {
  local input="$1"

  # Try menu items first
  if ui_handle_menu_selection "$input"; then
    return 0
  fi

  # Try footer actions
  # Check both uppercase and lowercase
  if ui_handle_footer_selection "$input"; then
    return 0
  fi

  local upper_input="${input^^}"
  if ui_handle_footer_selection "$upper_input"; then
    return 0
  fi

  local lower_input="${input,,}"
  if ui_handle_footer_selection "$lower_input"; then
    return 0
  fi

  # Input not handled
  return 1
}

# ui_main_loop
# Main UI loop - renders screen and handles input
ui_main_loop() {
  UI_LOOP_RUNNING=1
  UI_LOOP_EXIT_CODE=0

  while [[ $UI_LOOP_RUNNING -eq 1 ]]; do
    # Run pre-render callback
    if [[ -n "$UI_PRE_RENDER_CALLBACK" ]] && type -t "$UI_PRE_RENDER_CALLBACK" &>/dev/null; then
      "$UI_PRE_RENDER_CALLBACK"
    fi

    # Render screen
    ui_render_screen

    # Run post-render callback
    if [[ -n "$UI_POST_RENDER_CALLBACK" ]] && type -t "$UI_POST_RENDER_CALLBACK" &>/dev/null; then
      "$UI_POST_RENDER_CALLBACK"
    fi

    # Read input
    ui_read_input

    # Process input
    ui_process_input "$UI_INPUT"
  done

  return $UI_LOOP_EXIT_CODE
}

# ui_exit [exit_code]
# Exit the UI loop
ui_exit() {
  local exit_code="${1:-0}"
  UI_LOOP_RUNNING=0
  UI_LOOP_EXIT_CODE="$exit_code"
}

# ui_reload
# Reload/refresh the screen without waiting for input
ui_reload() {
  # Run pre-render callback
  if [[ -n "$UI_PRE_RENDER_CALLBACK" ]] && type -t "$UI_PRE_RENDER_CALLBACK" &>/dev/null; then
    "$UI_PRE_RENDER_CALLBACK"
  fi

  # Render screen
  ui_render_screen

  # Run post-render callback
  if [[ -n "$UI_POST_RENDER_CALLBACK" ]] && type -t "$UI_POST_RENDER_CALLBACK" &>/dev/null; then
    "$UI_POST_RENDER_CALLBACK"
  fi
}

# ui_submenu <function>
# Enter a submenu (clears current menu items, calls function, then returns)
# The function should set up its own menu items and call ui_main_loop
ui_submenu() {
  local submenu_function="$1"

  if ! type -t "$submenu_function" &>/dev/null; then
    ui_print_error "Submenu function '$submenu_function' not found"
    ui_pause
    return 1
  fi

  # Save current menu state
  local saved_menu_keys=("${UI_MENU_ITEMS_KEYS[@]}")
  local saved_menu_text=()
  local saved_menu_handler=()
  local saved_menu_condition=()

  for key in "${saved_menu_keys[@]}"; do
    saved_menu_text["$key"]="${UI_MENU_ITEMS_TEXT[$key]}"
    saved_menu_handler["$key"]="${UI_MENU_ITEMS_HANDLER[$key]}"
    saved_menu_condition["$key"]="${UI_MENU_ITEMS_CONDITION[$key]}"
  done

  # Clear current menu
  ui_clear_menu_items

  # Call submenu function
  "$submenu_function"

  # Restore menu state
  ui_clear_menu_items
  UI_MENU_ITEMS_KEYS=("${saved_menu_keys[@]}")
  for key in "${saved_menu_keys[@]}"; do
    UI_MENU_ITEMS_TEXT["$key"]="${saved_menu_text[$key]}"
    UI_MENU_ITEMS_HANDLER["$key"]="${saved_menu_handler[$key]}"
    UI_MENU_ITEMS_CONDITION["$key"]="${saved_menu_condition[$key]}"
  done
}

# ui_run_external_command <command> [args...]
# Run external command and return to menu
ui_run_external_command() {
  ui_clear_screen
  "$@"
  local result=$?
  echo
  ui_pause
  return $result
}

# Common action handlers that can be used by applications

# ui_action_exit
# Exit the UI loop
ui_action_exit() {
  ui_exit 0
}

# ui_action_reboot
# Reboot the system (requires confirmation)
ui_action_reboot() {
  if ui_confirm "Are you sure you want to reboot?"; then
    ui_print_info "Rebooting system..."
    sync
    reboot
  fi
}

# ui_action_poweroff
# Power off the system (requires confirmation)
ui_action_poweroff() {
  if ui_confirm "Are you sure you want to power off?"; then
    ui_print_info "Powering off system..."
    sync
    poweroff
  fi
}

# ui_action_shell
# Launch a shell
ui_action_shell() {
  ui_clear_screen
  echo "Entering shell. Type 'exit' or press Ctrl+D to return to menu."
  echo
  bash || /bin/sh
}

# ui_action_back
# Go back (exit current submenu)
ui_action_back() {
  ui_exit 0
}

# ui_simple_menu <title> <menu_item_pairs...>
# Create and run a simple menu without full setup
# Example: ui_simple_menu "Main Menu" "1" "Option 1" "handler1" "2" "Option 2" "handler2"
ui_simple_menu() {
  local title="$1"
  shift

  # Set up header
  ui_set_header_callback "ui_simple_menu_header"
  UI_SIMPLE_MENU_TITLE="$title"

  # Clear and add menu items
  ui_clear_menu_items

  while [[ $# -gt 0 ]]; do
    if [[ $# -lt 3 ]]; then
      ui_print_error "ui_simple_menu: incomplete menu item definition"
      return 1
    fi

    local key="$1"
    local text="$2"
    local handler="$3"
    shift 3

    ui_add_menu_item "$key" "$text" "$handler"
  done

  # Add default footer actions
  ui_clear_footer_actions
  ui_add_footer_action "Q" "quit" "ui_action_exit"

  # Run menu
  ui_main_loop
}

# ui_simple_menu_header
# Header for simple menu
ui_simple_menu_header() {
  ui_render_default_header "${UI_SIMPLE_MENU_TITLE:-Menu}"
}

# Initialize on load
ui_init
