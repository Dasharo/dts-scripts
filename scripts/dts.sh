#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# shellcheck source=../include/dts-environment.sh
source $DTS_ENV
# shellcheck source=../include/dts-functions.sh
source $DTS_FUNCS
# shellcheck source=../include/dts-subscription.sh
source $DTS_SUBS

trap : 2
trap : 3
trap wait_for_input EXIT

wait_for_input() {
  code=$?
  if [[ $code -ne 0 ]]; then
    read -p "Press Enter to continue."
  fi
  exit $code
}

while :; do
  clear
  # Header should always be printed:
  show_header
  if [ -z "$DPP_SUBMENU_ACTIVE" ]; then
    show_hardsoft_inf
    show_dpp_credentials
    show_ssh_info
    show_main_menu
  elif [ -n "$DPP_SUBMENU_ACTIVE" ]; then
    show_dpp_submenu
  fi
  show_footer

  echo
  read -n 1 OPTION
  echo

  # If OPTION is being matched with smth inside *_options functions the
  # functions return 0 and loop start over, if not: next *_options function is
  # being checked:
  if [ -z "$DPP_SUBMENU_ACTIVE" ]; then
    main_menu_options $OPTION && continue
  elif [ -n "$DPP_SUBMENU_ACTIVE" ]; then
    dpp_submenu_options $OPTION && continue
  fi

  footer_options $OPTION
done
