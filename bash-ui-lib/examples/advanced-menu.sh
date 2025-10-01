#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Advanced menu example with submenus, conditions, and custom themes

# Get the library directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

# Source the UI library
source "${LIB_DIR}/ui-core.sh"

# Application state
APP_FEATURE_ENABLED=false
APP_COUNTER=0

# Handlers for main menu
feature_toggle_handler() {
  ui_clear_screen
  if [[ "$APP_FEATURE_ENABLED" == "true" ]]; then
    APP_FEATURE_ENABLED=false
    ui_print_warning "Feature has been disabled"
  else
    APP_FEATURE_ENABLED=true
    ui_print_success "Feature has been enabled"
  fi
  echo
  ui_pause
}

increment_counter_handler() {
  ((APP_COUNTER++))
  ui_clear_screen
  ui_print_success "Counter incremented!"
  ui_print_info "Current value: $APP_COUNTER"
  echo
  ui_pause
}

reset_counter_handler() {
  if ui_confirm "Are you sure you want to reset the counter?"; then
    APP_COUNTER=0
    ui_print_success "Counter reset to 0"
  fi
  echo
  ui_pause
}

# Submenu handler
settings_menu_handler() {
  # Clear main menu
  ui_clear_menu_items

  # Add submenu items
  ui_add_menu_item "1" "Change Theme" "change_theme_handler"
  ui_add_menu_item "2" "View Statistics" "view_stats_handler"
  ui_add_menu_item "3" "Reset All Settings" "reset_settings_handler"

  # Override footer to add back button
  ui_clear_footer_actions
  ui_add_footer_action "B" "back to main menu" "return_to_main_handler"
  ui_add_footer_action "Q" "quit" "ui_action_exit"

  # Run submenu loop
  ui_main_loop

  # Restore main menu after submenu exits
  setup_main_menu
}

change_theme_handler() {
  ui_clear_screen
  ui_print_info "Theme Selection"
  echo

  ui_ask_choice "Select a color theme" \
    "1" "Default (Cyan/Yellow)" \
    "2" "Dark (Blue/Green)" \
    "3" "Light (Yellow/Red)"

  case "$UI_SELECTED_CHOICE" in
  1)
    UI_THEME[INFO]="${UI_COLORS[CYAN]}"
    UI_THEME[MENU_KEY]="${UI_COLORS[YELLOW]}"
    ui_print_success "Default theme activated"
    ;;
  2)
    UI_THEME[INFO]="${UI_COLORS[BLUE]}"
    UI_THEME[MENU_KEY]="${UI_COLORS[GREEN]}"
    ui_print_success "Dark theme activated"
    ;;
  3)
    UI_THEME[INFO]="${UI_COLORS[YELLOW]}"
    UI_THEME[MENU_KEY]="${UI_COLORS[RED]}"
    ui_print_success "Light theme activated"
    ;;
  esac

  echo
  ui_pause
}

view_stats_handler() {
  ui_clear_screen
  ui_print_info "=== Application Statistics ==="
  echo
  echo "Counter Value: $APP_COUNTER"
  echo "Feature Enabled: $APP_FEATURE_ENABLED"
  echo "Terminal Size: ${UI_TERM_WIDTH}x${UI_TERM_HEIGHT}"
  echo
  ui_pause
}

reset_settings_handler() {
  if ui_confirm "Reset all settings to defaults?"; then
    APP_FEATURE_ENABLED=false
    APP_COUNTER=0
    source "${LIB_DIR}/ui-colors.sh"  # Reload default theme
    ui_print_success "Settings reset to defaults"
  fi
  echo
  ui_pause
}

return_to_main_handler() {
  ui_exit 0
}

# Conditions for menu items
is_feature_enabled() {
  [[ "$APP_FEATURE_ENABLED" == "true" ]]
}

counter_not_zero() {
  [[ $APP_COUNTER -gt 0 ]]
}

# Custom header with dynamic info
my_header() {
  ui_render_default_header "Advanced Menu Example" "v1.0.0"
  echo -e "${UI_THEME[INFO]}Feature Status: ${APP_FEATURE_ENABLED} | Counter: ${APP_COUNTER}${UI_COLORS[NORMAL]}"
  ui_render_separator
}

# Custom info section
my_info_section() {
  echo -e "${UI_THEME[INFO]}Press the number keys to select menu options${UI_COLORS[NORMAL]}"
  echo -e "${UI_THEME[INFO]}Press letter keys for footer actions${UI_COLORS[NORMAL]}"
  ui_render_separator
}

# Set up main menu
setup_main_menu() {
  ui_clear_menu_items
  ui_clear_footer_actions

  # Add menu items with conditions
  ui_add_menu_item "1" "Toggle Feature (Currently: OFF)" "feature_toggle_handler" "! is_feature_enabled"
  ui_add_menu_item "1" "Toggle Feature (Currently: ON)" "feature_toggle_handler" "is_feature_enabled"
  ui_add_menu_item "2" "Increment Counter" "increment_counter_handler"
  ui_add_menu_item "3" "Reset Counter" "reset_counter_handler" "counter_not_zero"
  ui_add_menu_item "4" "Settings Menu" "settings_menu_handler"

  # Add footer actions
  ui_add_footer_action "Q" "quit" "ui_action_exit"
  ui_add_footer_action "S" "shell" "ui_action_shell"
}

# Set up UI
ui_set_header_callback "my_header"
ui_set_info_section_callback "my_info_section"

# Initial menu setup
setup_main_menu

# Run the menu loop
ui_main_loop
