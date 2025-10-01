#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# dts-ui-adapter.sh - Adapter to use bash-ui-lib with existing DTS code
# This provides compatibility functions that match the original DTS UI API

# Prevent multiple sourcing
if [[ -n "${_DTS_UI_ADAPTER_SOURCED}" ]]; then
  return 0
fi
_DTS_UI_ADAPTER_SOURCED=1

# Source the UI library
UI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${UI_LIB_DIR}/ui-core.sh"

# Map DTS color variables to UI library
NORMAL="${UI_COLORS[NORMAL]}"
RED="${UI_COLORS[RED]}"
YELLOW="${UI_COLORS[YELLOW]}"
GREEN="${UI_COLORS[GREEN]}"
BLUE="${UI_COLORS[CYAN]}"

# Map DTS functions to UI library functions
echo_green() { ui_echo_green "$@"; }
echo_red() { ui_echo_red "$@"; }
echo_yellow() { ui_echo_yellow "$@"; }
print_warning() { ui_print_warning "$@"; }
print_error() { ui_print_error "$@"; }
print_ok() { ui_print_success "$@"; }
clear_line() { ui_clear_line; }

# DTS-specific rendering functions using the UI library

# show_header
# Render DTS header with version info
show_header() {
  local _os_version
  _os_version=$(grep "VERSION_ID" "${OS_VERSION_FILE:-/etc/os-release}" 2>/dev/null | cut -d "=" -f 2- || echo "unknown")

  printf "\ec"
  echo -e "${NORMAL}\n Dasharo Tools Suite Script ${_os_version} ${NORMAL}"
  echo -e "${NORMAL} (c) Dasharo <contact@dasharo.com> ${NORMAL}"
  echo -e "${NORMAL} Report issues at: https://github.com/Dasharo/dasharo-issues ${NORMAL}"
}

# show_hardsoft_inf
# Show hardware and firmware information
show_hardsoft_inf() {
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${NORMAL}                HARDWARE INFORMATION ${NORMAL}"
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${YELLOW}    System Inf.: ${NORMAL}${SYSTEM_VENDOR:-Unknown} ${SYSTEM_MODEL:-Unknown}"
  echo -e "${BLUE}**${YELLOW} Baseboard Inf.: ${NORMAL}${SYSTEM_VENDOR:-Unknown} ${BOARD_MODEL:-Unknown}"
  echo -e "${BLUE}**${YELLOW}       CPU Inf.: ${NORMAL}${CPU_VERSION:-Unknown}"

  if type -t show_ram_inf &>/dev/null; then
    show_ram_inf
  fi

  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${NORMAL}                FIRMWARE INFORMATION ${NORMAL}"
  echo -e "${BLUE}*********************************************************${NORMAL}"
  echo -e "${BLUE}**${YELLOW} BIOS Inf.: ${NORMAL}${BIOS_VENDOR:-Unknown} ${BIOS_VERSION:-Unknown}"
  echo -e "${BLUE}*********************************************************${NORMAL}"
}

# show_dpp_credentials
# Show DPP credentials (if logged in)
show_dpp_credentials() {
  if [[ -n "${DPP_IS_LOGGED}" ]]; then
    echo -e "${BLUE}**${NORMAL}                DPP credentials ${NORMAL}"
    echo -e "${BLUE}*********************************************************${NORMAL}"
    if [[ "${DISPLAY_CREDENTIALS}" == "true" ]]; then
      echo -e "${BLUE}**${YELLOW}      Email: ${NORMAL}${DPP_EMAIL:-Unknown}"
      echo -e "${BLUE}**${YELLOW}   Password: ${NORMAL}${DPP_PASSWORD:-****}"
    else
      echo -e "${BLUE}**${YELLOW}      Email: ***************"
      echo -e "${BLUE}**${YELLOW}   Password: ***************"
    fi
    echo -e "${BLUE}*********************************************************${NORMAL}"
  fi
}

# show_ssh_info
# Show SSH server status and IP addresses
show_ssh_info() {
  if systemctl is-active sshd.service >/dev/null 2>&1; then
    local ip=""
    ip=$(ip -br -f inet a show scope global 2>/dev/null | grep UP | awk '{ print $3 }' | tr '\n' ' ')

    if [[ -z "$ip" ]]; then
      echo -e "${BLUE}**${NORMAL}    SSH status: ${GREEN}ON${NORMAL} IP: ${RED}check your connection${NORMAL}"
      echo -e "${BLUE}*********************************************************${NORMAL}"
    else
      echo -e "${BLUE}**${NORMAL}    SSH status: ${GREEN}ON${NORMAL} IP: ${ip}${NORMAL}"
      echo -e "${BLUE}*********************************************************${NORMAL}"
    fi
  fi
}

# show_main_menu
# Show main menu using UI library
show_main_menu() {
  # Check if this is first time setup - if so, build menu from registered items
  if [[ "${#UI_MENU_ITEMS_KEYS[@]}" -eq 0 ]]; then
    # Menu not set up yet, use default DTS menu
    _setup_default_dts_menu
  fi

  # Render menu using UI library
  ui_render_menu
}

# _setup_default_dts_menu
# Set up default DTS menu items (internal helper)
_setup_default_dts_menu() {
  # This is a fallback - normally menu should be set up by caller
  # Add basic menu structure

  if type -t check_if_dasharo &>/dev/null && check_if_dasharo; then
    ui_add_menu_item "${DASHARO_FIRM_OPT:-2}" "Update Dasharo Firmware" "_dts_menu_update_firmware"
  elif [[ "${SYSTEM_VENDOR:-}" != "QEMU" && "${SYSTEM_VENDOR:-}" != "Emulation" ]]; then
    ui_add_menu_item "${DASHARO_FIRM_OPT:-2}" "Install Dasharo Firmware" "_dts_menu_install_firmware"
  fi

  ui_add_menu_item "${HCL_REPORT_OPT:-1}" "Dasharo HCL report" "_dts_menu_hcl_report"

  if [[ "${SYSTEM_VENDOR:-}" != "QEMU" && "${SYSTEM_VENDOR:-}" != "Emulation" ]]; then
    ui_add_menu_item "${REST_FIRM_OPT:-3}" "Restore firmware from Dasharo HCL report" "_dts_menu_restore_firmware"
  fi
}

# show_footer
# Show footer with actions using UI library
show_footer() {
  # Render DTS-style footer directly (don't call ui_render_footer to avoid recursion)
  _setup_default_dts_footer
}

# _setup_default_dts_footer
# Set up default DTS footer actions (internal helper)
_setup_default_dts_footer() {
  echo -e "${BLUE}*********************************************************${NORMAL}"

  echo -ne "${RED}${REBOOT_OPT_UP:-R}${NORMAL} to reboot  ${NORMAL}"
  echo -ne "${RED}${POWEROFF_OPT_UP:-P}${NORMAL} to poweroff  ${NORMAL}"
  echo -e "${RED}${SHELL_OPT_UP:-S}${NORMAL} to enter shell  ${NORMAL}"

  # Safely check SSH status - avoid segfault from systemctl issues
  local ssh_status="inactive"
  if command -v systemctl &>/dev/null; then
    ssh_status=$(systemctl is-active sshd.service 2>/dev/null || echo "inactive")
  fi

  if [[ "$ssh_status" == "active" ]]; then
    echo -ne "${RED}${SSH_OPT_UP:-K}${NORMAL} to stop SSH server  ${NORMAL}"
  else
    echo -ne "${RED}${SSH_OPT_UP:-K}${NORMAL} to launch SSH server  ${NORMAL}"
  fi

  if [[ "${SEND_LOGS_ACTIVE}" == "true" ]]; then
    echo -e "${RED}${SEND_LOGS_OPT:-L}${NORMAL} to disable sending DTS logs ${NORMAL}"
  else
    echo -e "${RED}${SEND_LOGS_OPT:-L}${NORMAL} to enable sending DTS logs ${NORMAL}"
  fi

  if [[ -n "${DPP_IS_LOGGED}" ]]; then
    if [[ "${DISPLAY_CREDENTIALS}" == "true" ]]; then
      echo -e "${RED}${TOGGLE_DISP_CRED_OPT_UP:-C}${NORMAL} to hide DPP credentials ${NORMAL}"
    else
      echo -e "${RED}${TOGGLE_DISP_CRED_OPT_UP:-C}${NORMAL} to display DPP credentials ${NORMAL}"
    fi
  fi

  echo -ne "${YELLOW}\nEnter an option:${UI_COLORS[NORMAL]} "
}

# Wrapper for DTS main_menu_options
# This maintains compatibility with existing DTS code
main_menu_options() {
  local OPTION="$1"

  # Try to process input using UI library first
  if ui_process_input "$OPTION"; then
    return 0
  fi

  # If not handled by UI library, fall back to original handler if it exists
  if type -t _original_main_menu_options &>/dev/null; then
    _original_main_menu_options "$OPTION"
    return $?
  fi

  return 1
}

# Wrapper for DTS footer_options
# This maintains compatibility with existing DTS code
footer_options() {
  local OPTION="$1"

  # Try to process input using UI library first
  if ui_process_input "$OPTION"; then
    return 0
  fi

  # If not handled by UI library, fall back to original handler if it exists
  if type -t _original_footer_options &>/dev/null; then
    _original_footer_options "$OPTION"
    return $?
  fi

  return 1
}

# Helper function to register DTS menu items with UI library
dts_register_menu_item() {
  local key="$1"
  local text="$2"
  local handler="$3"
  local condition="${4:-}"

  ui_add_menu_item "$key" "$text" "$handler" "$condition"
}

# Helper function to register DTS footer actions with UI library
dts_register_footer_action() {
  local key="$1"
  local text="$2"
  local handler="$3"
  local condition="${4:-}"

  ui_add_footer_action "$key" "$text" "$handler" "$condition"
}

# Helper to set up DTS-style UI
dts_setup_ui() {
  # Set up header callback
  ui_set_header_callback "show_header"

  # Set up info section callback
  ui_set_info_section_callback "_dts_info_section"

  # Set up footer callback
  ui_set_footer_callback "show_footer"

  # Use single character input mode
  ui_set_input_mode "single"
}

# Internal info section for DTS
_dts_info_section() {
  show_hardsoft_inf
  show_dpp_credentials
  show_ssh_info
}
