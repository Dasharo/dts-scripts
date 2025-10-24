#!/usr/bin/env bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"
# shellcheck source=../../include/dts-functions.sh
source "$DTS_FUNCS"

print_disclaimer
if ask_for_confirmation "Do you want to support Dasharo development by sending us logs with your hardware configuration?"; then
  export SEND_LOGS="true"
  tui_echo_normal "Thank you for contributing to the Dasharo development!"
else
  export SEND_LOGS="false"
  tui_echo_normal "Logs will be saved in root directory."
  tui_echo_normal "Please consider supporting Dasharo by sending the logs next time."
fi
if [ "${SEND_LOGS}" == "true" ]; then
  # DEPLOY_REPORT variable is used in dasharo-hcl-report to determine
  # which logs should be printed in the terminal, in the future whole
  # dts scripting should get some LOGLEVEL and maybe dumping working
  # logs to file
  export DEPLOY_REPORT="false"
  wait_for_network_connection && ${CMD_DASHARO_HCL_REPORT}
else
  export DEPLOY_REPORT="false"
  ${CMD_DASHARO_HCL_REPORT}
fi
