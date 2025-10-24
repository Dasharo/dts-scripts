#!/usr/bin/env bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"
# shellcheck source=../../include/dts-functions.sh
source "$DTS_FUNCS"

SEND_LOGS_ACTIVE=$(get_global_state SEND_LOGS_ACTIVE)
if [ "${SEND_LOGS_ACTIVE}" = "true" ]; then
  set_global_state SEND_LOGS_ACTIVE "false"
else
  set_global_state SEND_LOGS_ACTIVE "true"
fi
