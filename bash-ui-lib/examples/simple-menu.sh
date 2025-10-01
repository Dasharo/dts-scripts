#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Simple menu example using bash-ui-lib

# Get the library directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

# Source the UI library
source "${LIB_DIR}/ui-core.sh"

# Define menu handlers
option1_handler() {
  ui_clear_screen
  ui_print_success "Option 1 was selected!"
  echo
  echo "This is where you would implement the actual functionality."
  echo
  ui_pause
}

option2_handler() {
  ui_clear_screen
  ui_print_success "Option 2 was selected!"
  echo

  if ui_confirm "Do you want to continue?"; then
    ui_print_info "You confirmed!"
  else
    ui_print_warning "You declined."
  fi

  echo
  ui_pause
}

option3_handler() {
  ui_clear_screen
  ui_print_success "Option 3 was selected!"
  echo

  ui_ask_choice "Select a sub-option" \
    "a" "Sub-option A" \
    "b" "Sub-option B" \
    "c" "Sub-option C"

  echo
  ui_print_info "You selected: $UI_SELECTED_CHOICE"
  echo
  ui_pause
}

# Custom header
my_header() {
  ui_render_default_header "Simple Menu Example" "Powered by bash-ui-lib"
}

# Set up the menu
ui_set_header_callback "my_header"

ui_add_menu_item "1" "First Option" "option1_handler"
ui_add_menu_item "2" "Second Option (with confirmation)" "option2_handler"
ui_add_menu_item "3" "Third Option (with sub-menu)" "option3_handler"

# Add footer actions
ui_add_footer_action "Q" "quit" "ui_action_exit"
ui_add_footer_action "S" "shell" "ui_action_shell"

# Run the menu loop
ui_main_loop
