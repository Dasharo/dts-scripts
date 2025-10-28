#!/usr/bin/env bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"
# shellcheck source=../../include/dts-functions.sh
source "$DTS_FUNCS"

[ "${SYSTEM_VENDOR}" = "QEMU" ] || [ "${SYSTEM_VENDOR}" = "Emulation" ] && exit 0

if check_if_dasharo; then
  if ! ${CMD_DASHARO_DEPLOY} restore; then
    send_dts_logs ask && exit 0
  fi
fi
