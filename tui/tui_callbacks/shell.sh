#!/usr/bin/env bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"
# shellcheck source=../../include/dts-functions.sh
source "$DTS_FUNCS"

tui_echo_normal "Entering shell, to leave type exit and press Enter or press LCtrl+D"
tui_echo_normal ""
send_dts_logs
stop_logging
${CMD_SHELL}
start_logging
