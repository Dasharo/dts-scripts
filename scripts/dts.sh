#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0
# shellcheck disable=SC2034

# shellcheck source=../include/dts-environment.sh
source $DTS_ENV
# shellcheck source=../include/dts-functions.sh
source $DTS_FUNCS
# shellcheck source=../include/dts-subscription.sh
source $DTS_SUBS

# those won't change
DTS_VERSION=$(grep "VERSION_ID" ${OS_VERSION_FILE} | cut -d "=" -f 2-)
RAM_INFO="$(show_ram_inf)"
SHOW_DASHARO_FIRMWARE="true"
if check_if_dasharo; then
  SHOW_TRANSITION="true"
  SHOW_FUSE="true"
else
  SHOW_TRANSITION="false"
  SHOW_FALSE="false"
fi

set_menu_vars() {
  DPP_IS_LOGGED=$(get_global_state DPP_IS_LOGGED)
  DISPLAY_CREDENTIALS=$(get_global_state DISPLAY_CREDENTIALS)

  if check_if_dasharo; then
    DASHARO_FIRMWARE_LABEL="Update Dasharo Firmware"
  else
    DASHARO_FIRMWARE_LABEL="Install Dasharo Firmware"
  fi
  if [ "${SYSTEM_VENDOR}" != "QEMU" ] && [ "${SYSTEM_VENDOR}" != "Emulation" ]; then
    SHOW_RESTORE_FIRMWARE="true"
  else
    SHOW_RESTORE_FIRMWARE="false"
  fi

  if [ "${DPP_IS_LOGGED}" = "true" ]; then
    DPP_KEYS_LABEL="Edit your DPP keys"
  else
    DPP_KEYS_LABEL="Load your DPP keys"
  fi
  if systemctl is-active sshd &>/dev/null; then
    SSH_STATUS="$(tui_echo_green ON)"
    SSH_IP="$(show_ssh_info)"
    SSH_LABEL="stop SSH server"
    SSH_ACTIVE="true"
  else
    SSH_LABEL="launch SSH server"
    SSH_ACTIVE="false"
  fi
  SEND_LOGS_ACTIVE=$(get_global_state SEND_LOGS_ACTIVE)
  if [ "${SEND_LOGS_ACTIVE}" = "true" ]; then
    SEND_LOGS_LABEL="disable sending DTS logs"
  else
    SEND_LOGS_LABEL="enable sending DTS logs"
  fi

  if [ "${DISPLAY_CREDENTIALS}" = "true" ]; then
    DPP_EMAIL_DISPLAY=$(mc alias ls premium --json | jq -r '.accessKey')
    DPP_PASSWORD_DISPLAY=$(mc alias ls premium --json | jq -r '.secretKey')
    DISPLAY_CRED_LABEL="hide DPP credentials"
  else
    DPP_EMAIL_DISPLAY="***************"
    DPP_PASSWORD_DISPLAY="***************"
    DISPLAY_CRED_LABEL="display DPP credentials"
  fi
}

tui_register_pre_render_callback subscription_routine
tui_register_pre_render_callback set_menu_vars
tui_register_pre_render_callback stop_trace_logging
tui_register_post_render_callback start_trace_logging
tui_run "$DTS_TUI_CONF"
