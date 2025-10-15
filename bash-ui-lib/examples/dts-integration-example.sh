#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Example showing how to integrate bash-ui-lib with existing DTS code

# Get the library directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

# Source the DTS adapter (which loads the UI library)
source "${LIB_DIR}/dts-ui-adapter.sh"

# Mock some DTS variables (in real DTS, these come from environment)
SYSTEM_VENDOR="Example Inc."
SYSTEM_MODEL="Example Model 123"
BOARD_MODEL="Example Board"
CPU_VERSION="Example CPU 3.0GHz"
BIOS_VENDOR="Dasharo"
BIOS_VERSION="Dasharo v1.2.3"
OS_VERSION_FILE="/etc/os-release"

# DTS-style menu handlers
dts_hcl_report_handler() {
  ui_clear_screen
  echo_green "Generating HCL Report..."
  echo
  echo "This would normally:"
  echo "  - Collect hardware information"
  echo "  - Create detailed report"
  echo "  - Upload to Dasharo servers (optional)"
  echo
  print_ok "HCL Report generated successfully!"
  echo
  ui_pause
}

dts_update_firmware_handler() {
  ui_clear_screen
  echo_yellow "Checking for firmware updates..."
  echo
  echo "Current version: ${BIOS_VERSION}"
  echo "Latest version:  Dasharo v1.3.0"
  echo

  if ui_confirm "Update to latest version?"; then
    echo
    echo_green "Downloading firmware..."

    # Simulate download with progress bar
    for i in {1..100}; do
      ui_progress_bar $i 100 50
      sleep 0.02
    done
    echo

    print_ok "Firmware updated successfully!"
    echo
    print_warning "Please reboot to apply changes"
  else
    print_warning "Update cancelled"
  fi

  echo
  ui_pause
}

dts_restore_firmware_handler() {
  ui_clear_screen
  echo_yellow "Restore Firmware from HCL Report"
  echo
  echo "Available backups:"
  echo "  1. backup_2024_01_15.rom (16 MB)"
  echo "  2. backup_2024_02_20.rom (16 MB)"
  echo "  3. backup_2024_03_10.rom (16 MB)"
  echo

  if ui_confirm "Select and restore a backup?"; then
    ui_ask_choice "Select backup to restore" \
      "1" "backup_2024_01_15.rom" \
      "2" "backup_2024_02_20.rom" \
      "3" "backup_2024_03_10.rom"

    echo
    echo_green "Restoring backup ${UI_SELECTED_CHOICE}..."
    echo
    print_warning "This is a simulation - no actual changes made"
  else
    print_warning "Restore cancelled"
  fi

  echo
  ui_pause
}

dts_load_dpp_keys_handler() {
  ui_clear_screen
  echo_yellow "Load DPP (Dasharo Pro Package) Keys"
  echo

  read -p "Enter email: " email
  read -sp "Enter password: " password
  echo
  echo

  if [[ -n "$email" && -n "$password" ]]; then
    echo_green "Validating credentials..."
    sleep 1
    print_ok "Successfully logged in to DPP"
    echo
    echo "Your credentials give access to:"
    echo "  ✓ Dasharo Pro Package (DPP)"
    echo "  ✓ DTS Extensions"
  else
    print_error "Email and password are required"
  fi

  echo
  ui_pause
}

# DTS-style footer handlers
ssh_toggle_handler() {
  ui_clear_screen
  print_warning "SSH Toggle (simulated)"
  echo
  echo "This would:"
  echo "  - Check if SSH is running"
  echo "  - Start/stop SSH service"
  echo "  - Display IP addresses"
  echo
  ui_pause
}

# Custom header matching DTS style
dts_custom_header() {
  local _os_version
  _os_version=$(grep "VERSION_ID" "${OS_VERSION_FILE}" 2>/dev/null | cut -d "=" -f 2- | tr -d '"' || echo "unknown")

  printf "\ec"
  echo "" # Blank line
  ui_print_simple_line " Dasharo Tools Suite Script ${_os_version}"
  ui_print_simple_line " (c) Dasharo <contact@dasharo.com>"
  ui_print_simple_line " Report issues at: https://github.com/Dasharo/dasharo-issues"
}

# Set up DTS-style UI using the library
dts_setup_ui

# Override header with DTS-specific header
ui_set_header_callback "dts_custom_header"

# Register menu items using the library
ui_clear_menu_items
ui_clear_footer_actions

# Main menu items
ui_add_menu_item "1" "Dasharo HCL report" "dts_hcl_report_handler"
ui_add_menu_item "2" "Update Dasharo Firmware" "dts_update_firmware_handler"
ui_add_menu_item "3" "Restore firmware from Dasharo HCL report" "dts_restore_firmware_handler"
ui_add_menu_item "4" "Load your DPP keys" "dts_load_dpp_keys_handler"

# Footer actions
ui_add_footer_action "R" "reboot" "ui_action_reboot"
ui_add_footer_action "P" "poweroff" "ui_action_poweroff"
ui_add_footer_action "S" "enter shell" "ui_action_shell"
ui_add_footer_action "K" "toggle SSH" "ssh_toggle_handler"
ui_add_footer_action "Q" "quit" "ui_action_exit"

# Run the menu
ui_main_loop
