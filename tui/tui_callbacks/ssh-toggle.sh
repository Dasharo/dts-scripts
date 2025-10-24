#!/usr/bin/env bash

# shellcheck disable=SC1090
source "$DTS_TUI_LIB"

if systemctl is-active sshd &>/dev/null; then
  tui_echo_green "Turning off the SSH server..."
  systemctl stop sshd
else
  tui_echo_yellow "Starting SSH server!"
  tui_echo_yellow "Now you can log in into the system using root account."
  tui_echo_yellow "Stopping server will not drop all connected sessions."
  systemctl start sshd
  tui_echo_green "Listening on IPs: $(ip -br -f inet a show scope global | grep UP | awk '{ print $3 }' | tr '\n' ' ')"
fi
