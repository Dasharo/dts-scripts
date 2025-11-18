#!/usr/bin/env bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"
# shellcheck source=../../include/dts-functions.sh
source "$DTS_FUNCS"

# No transition, if there is no Dasharo firmware installed:
check_if_dasharo || exit 0

${CMD_DASHARO_DEPLOY} transition
result=$?
if [ "$result" -ne $OK ] && [ "$result" -ne $CANCEL ]; then
  send_dts_logs ask && exit $OK
fi
