#!/usr/bin/env bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"
# shellcheck source=../../include/dts-functions.sh
source "$DTS_FUNCS"
# shellcheck source=../../include/dts-subscription.sh
source $DTS_SUBS

_result=
# Return if there was an issue when asking for credentials:
if ! get_dpp_creds; then
  exit 0
fi

# Try to log in using available DPP credentials, start loop over if login
# was not successful:
if ! login_to_dpp_server; then
  tui_echo_normal "Cannot log in to DPP server."
  exit 0
fi

# Check for Dasharo Firmware for the current platform, continue to
# packages after checking:
check_for_dasharo_firmware
_result=$?
tui_echo_normal "Your credentials give access to:"
echo -n "Dasharo Pro Package (DPP): "
if [ $_result -eq 0 ]; then
  # FIXME: what if credentials have access to
  # firmware, but check_for_dasharo_firmware will not detect any platform?
  # According to check_for_dasharo_firmware it will return 1 in both
  # cases which means that we cannot detect such case.
  tui_echo_normal "Dasharo Pro Package (DPP): $(tui_echo_green YES)"
else
  tui_echo_normal "Dasharo Pro Package (DPP): NO"
fi

echo -n "DTS Extensions: "

if check_dts_extensions_access; then
  tui_echo_normal "DTS Extensions: $(tui_echo_green YES)"
  check_avail_dpp_packages && install_all_dpp_packages && parse_for_premium_submenu
else
  tui_echo_normal "DTS Extensions: NO"
fi
