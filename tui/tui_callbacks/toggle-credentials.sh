#!/usr/bin/env bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"
# shellcheck source=../../include/dts-functions.sh
source "$DTS_FUNCS"

DISPLAY_CREDENTIALS=$(get_global_state DISPLAY_CREDENTIALS)
if [ "${DISPLAY_CREDENTIALS}" = "true" ]; then
  set_global_state DISPLAY_CREDENTIALS "false"
else
  set_global_state DISPLAY_CREDENTIALS "true"
fi
