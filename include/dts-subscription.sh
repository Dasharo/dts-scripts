#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# shellcheck disable=SC2034

check_for_dasharo_firmware() {
  # This function checks if Dasharo firmware is available for the current
  # platform, returns 1 if there is no firmware available, returns 0 otherwise.

  echo "Checking for Dasharo firmware..."

  if ! [ -f "$DPP_CREDENTIAL_FILE" ]; then
    print_warning "No credentials provided, cannot check for Dasharo firmware access."
    return 1
  fi

  local _check_dwn_req_resp_uefi="0"
  local _check_dwn_req_resp_uefi_cap="0"
  local _check_dwn_req_resp_heads="0"
  local _check_dwn_req_resp_seabios="0"
  local _check_logs_req_resp="0"
  # Ignore "SC2154 (warning): DPP_CREDENTIAL_FILE is referenced but not assigned"
  # for external variable:
  # shellcheck disable=SC2154
  DPP_EMAIL=$(sed -n '1p' <${DPP_CREDENTIAL_FILE} | tr -d '\n')
  DPP_PASSWORD=$(sed -n '2p' <${DPP_CREDENTIAL_FILE} | tr -d '\n')

  # Check the board information:
  board_config

  # If board_config function has not set firmware links - exit with warning:
  if [ -z "$BIOS_LINK_DPP" ] && [ -z "$HEADS_LINK_DPP" ] && [ -z "$BIOS_LINK_DPP_SEABIOS" ] && [ -z "$BIOS_LINK_DPP_CAP" ]; then
    print_warning "There is no Dasharo Firmware available for your platform."
    return 1
  fi

  # Check for firmware binaries:
  if wait_for_network_connection; then
    if [ -n "$BIOS_LINK_DPP" ]; then
      mc find "${DPP_SERVER_USER_ALIAS}/${BIOS_LINK_DPP}" >/dev/null 2>>"$ERR_LOG_FILE"
      _check_dwn_req_resp_uefi=$?
    fi

    if [ -n "$BIOS_LINK_DPP_CAP" ]; then
      mc find "${DPP_SERVER_USER_ALIAS}/${BIOS_LINK_DPP_CAP}" >/dev/null 2>>"$ERR_LOG_FILE"
      _check_dwn_req_resp_uefi_cap=$?
    fi

    if [ -n "$HEADS_LINK_DPP" ]; then
      mc find "${DPP_SERVER_USER_ALIAS}/${HEADS_LINK_DPP}" >/dev/null 2>>"$ERR_LOG_FILE"
      _check_dwn_req_resp_heads=$?
    fi

    if [ -n "$BIOS_LINK_DPP_SEABIOS" ]; then
      mc find "${DPP_SERVER_USER_ALIAS}/${BIOS_LINK_DPP_SEABIOS}" >/dev/null 2>>"$ERR_LOG_FILE"
      _check_dwn_req_resp_seabios=$?
    fi
    if [ -n "${DPP_EMAIL}" ]; then
      mc find "${DPP_SERVER_USER_ALIAS}/${DPP_BUCKET}" >/dev/null 2>>"$ERR_LOG_FILE"
      _check_logs_req_resp=$?
    fi
  fi
  # Return 0 if any of Dasharo Firmware binaries is available:
  if [ ${_check_dwn_req_resp_uefi} -eq 0 ] || [ ${_check_dwn_req_resp_uefi_cap} -eq 0 ] || [ ${_check_dwn_req_resp_heads} -eq 0 ] || [ ${_check_dwn_req_resp_seabios} -eq 0 ]; then
    if [ ${_check_logs_req_resp} -eq 0 ]; then
      print_ok "A Dasharo Firmware binary has been found for your platform!"
      return 0
    fi
  fi

  print_warning "Something may be wrong with the DPP credentials or you may not"
  print_warning "have access to Dasharo Firmware. If so, consider getting Dasharo"
  print_warning "Subscription and improving security of your platform!"

  read -p "Press Enter to continue."
  return 1
}

check_dts_extensions_access() {
  if ! [ -f "$DPP_CREDENTIAL_FILE" ]; then
    print_warning "No credentials provided, cannot check for DTS Extensions access."
    return 1
  fi

  DPP_EMAIL=$(sed -n '1p' <${DPP_CREDENTIAL_FILE} | tr -d '\n')
  DPP_PASSWORD=$(sed -n '2p' <${DPP_CREDENTIAL_FILE} | tr -d '\n')

  if ! mc ls "${DPP_SERVER_USER_ALIAS}/des-packages/" >/dev/null 2>>"$ERR_LOG_FILE"; then
    return 1
  fi
  return 0
}

get_dpp_creds() {
  echo ""
  read -p "Enter DPP email:   " 'DPP_EMAIL'
  echo ""
  read -p "Enter password:    " 'DPP_PASSWORD'

  # Export DPP creds to a file for future use. Currently these are being used
  # for both: MinIO (and its mc CLI) and cloudsend (deprecated, all DPP
  # sibscribtions will be megrated to MinIO):
  echo ${DPP_EMAIL} >>${DPP_CREDENTIAL_FILE}
  echo ${DPP_PASSWORD} >>${DPP_CREDENTIAL_FILE}

  print_ok "Dasharo DPP credentials have been saved"
}

login_to_dpp_server() {
  # Check if the user is already logged in, log in if not:
  if [ -z "$(mc alias list | grep ${DPP_EMAIL})" ]; then
    if ! mc alias set $DPP_SERVER_USER_ALIAS $DPP_SERVER_ADDRESS $DPP_EMAIL $DPP_PASSWORD >/dev/null 2>>"$ERR_LOG_FILE"; then
      return 1
    fi
  fi

  return 0
}

subscription_routine() {
  # This function contains Subscription-related code which needs to be executed
  # several times. Currently it is called only in /usr/sbin/dts script at every
  # start of menu rendering loop.
  #
  # Currently it does the following:
  # Managing DPP creds., so the loop will detect them;
  # Connects to DPP server.
  export DPP_EMAIL
  export DPP_PASSWORD

  # Each time the main menu is rendered, check for DPP credentials and export
  # them, if file exists
  if [ -e "${DPP_CREDENTIAL_FILE}" ]; then
    DPP_EMAIL=$(sed -n '1p' <${DPP_CREDENTIAL_FILE} | tr -d '\n')
    DPP_PASSWORD=$(sed -n '2p' <${DPP_CREDENTIAL_FILE} | tr -d '\n')
    export DPP_IS_LOGGED="true"
  else
    unset DPP_EMAIL
    unset DPP_IS_LOGGED
    return 1
  fi

  # Network connection may not be available on boot, do not connect if so:
  check_network_connection && login_to_dpp_server || return 0

  return 0
}

check_dasharo_package_env() {
  [ -d $DPP_PACKAGE_MANAGER_DIR ] || mkdir -p $DPP_PACKAGE_MANAGER_DIR
  [ -d $DPP_PACKAGES_SCRIPTS_PATH ] || mkdir -p $DPP_PACKAGES_SCRIPTS_PATH

  return 0
}

update_package_list() {
  check_dasharo_package_env

  mc find --json --name "*.rpm" $DPP_SERVER_USER_ALIAS >$DPP_AVAIL_PACKAGES_LIST

  if [ $? -ne 0 ]; then
    print_error "Unable to get package list!"
    return 1
  fi
  return 0
}

download_dpp_package() {
  local package_name=$1

  # Make sure all paths exist:
  check_dasharo_package_env

  echo "Downloading package $package_name..."

  # Get package link:
  local download_link
  download_link=$(jq -r '.key' "$DPP_AVAIL_PACKAGES_LIST" | grep "$package_name")

  if [ -z "$download_link" ]; then
    print_error "No package $package_name found!"
    return 1
  fi

  # TODO: this will overwrite file with name package_name if its exists, a place
  # for improvements:
  local local_path="$DPP_PACKAGE_MANAGER_DIR/$package_name"
  mc get --quiet "$download_link" "$local_path"

  [ $? -ne 0 ] && return 1

  print_ok "Package $package_name have been downloaded successfully!"
  return 0
}

install_dpp_package() {
  local package_name=$1

  check_dasharo_package_env

  echo "Installing package $package_name..."

  update_package_list || return 1

  if [ ! -f "$DPP_PACKAGE_MANAGER_DIR/$package_name" ]; then
    download_dpp_package $package_name || return 1
  fi

  dnf --assumeyes install $DPP_PACKAGE_MANAGER_DIR/$package_name

  if [ $? -ne 0 ]; then
    rm -f $DPP_PACKAGE_MANAGER_DIR/$package_name
    print_error "Could not install package $package_name!"
    return 1
  fi

  rm -f $DPP_PACKAGE_MANAGER_DIR/$package_name

  print_ok "Package $package_name have been installed successfully!"
  return 0
}

install_all_dpp_packages() {
  echo "Installing available DTS extensions..."

  update_package_list || return 1

  # Strip out exact packages download links from the .json data:
  local packages_to_download
  packages_to_download=$(jq -r '.key' "$DPP_AVAIL_PACKAGES_LIST")

  if [ -z "$packages_to_download" ]; then
    echo "No packages to install."
    return 1
  fi

  echo "$packages_to_download" | while read -r download_link; do
    # Define the local file path:
    local package_name
    package_name=$(basename "$download_link")

    install_dpp_package $package_name
  done

  return 0
}

check_avail_dpp_packages() {
  echo "Checking for available DTS extensions..."
  AVAILABLE_PACKAGES=$(mc find --name "*.rpm" $DPP_SERVER_USER_ALIAS)

  if [ -z "$AVAILABLE_PACKAGES" ]; then
    return 1
  fi

  return 0
}

parse_for_premium_submenu() {
  [ -d $DPP_PACKAGES_SCRIPTS_PATH ] || return 0

  # Check if the JSON file exists, delete if so. The reason for it is that three
  # operations can be performed on this file: add new script inf., delete a
  # script inf., and update already existing script inf.. By deleting the
  # existing inf. and reparsing - three operations can be replaced with one:
  # deleting and updating - there is no need to delete or update if its being
  # recreated every time.
  [ -f "$DPP_SUBMENU_JSON" ] && rm -f "$DPP_SUBMENU_JSON"

  # submenu's options start from position 0:
  local position="1"
  local json_data='[]'

  # Iterate over bash scripts in the directory:
  for script in "$DPP_PACKAGES_SCRIPTS_PATH"/*; do
    # Skip if not a script:
    [ -n "$(file $script | grep 'script, ASCII text executable')" ] || continue

    # Create the JSON file only if any script have been found, this will be a
    # signal to render premium submenu:
    [ -f "$DPP_SUBMENU_JSON" ] || echo '[]' >"$DPP_SUBMENU_JSON"

    local script_name
    script_name=$(basename "$script")

    # Add a new entry to the JSON file
    json_data=$(jq --arg name "$script_name" --argjson pos "$position" \
      '. += [{"file_name": $name, "file_menu_position": $pos}]' <<<"$json_data")

    # Increment highest position for next script
    position=$((position + 1))
  done

  # Save updated JSON data
  [ -f "$DPP_SUBMENU_JSON" ] && echo "$json_data" | jq '.' >"$DPP_SUBMENU_JSON"

  return 0
}

show_dpp_submenu() {
  # This menu is being rendered dynamically by parsing scripts from
  # DPP_PACKAGES_SCRIPTS_PATH. These scripts are being installed by DPP
  # packages.
  #
  # Every script should contain menu_point function which should utilize one
  # argument. The argument is a menu position (an integer from zero to infinity;
  # represented by file_menu_position in the JSON file) which signal a position
  # in graphical submenu.

  echo -e "${BLUE}*********************************************************${NORMAL}"

  local file_menu_position

  # Read JSON data:
  local json_data
  json_data=$(jq -c '.[]' "$DPP_SUBMENU_JSON")

  # Iterate over each JSON object:
  while IFS= read -r item; do
    local script_name
    script_name=$(jq -r '.file_name' <<<"$item")
    file_menu_position=$(jq -r '.file_menu_position' <<<"$item")

    local script_path="$DPP_PACKAGES_SCRIPTS_PATH/$script_name"

    bash "$script_path" menu_point "$file_menu_position"

  done <<<"$json_data"

  echo -e "${BLUE}**${YELLOW}     ${BACK_TO_MAIN_MENU_UP})${BLUE} Return to main menu${NORMAL}"

  return 0
}

dpp_submenu_options() {
  local OPTION=$1
  local file_menu_position
  local script

  # Do not check JSON file if alphabetical option have been provided to not to
  # cause jq error:
  if [[ "$OPTION" =~ ^[0-9]+$ ]]; then
    # Look for option in JSON file;
    script=$(jq --argjson pos "$OPTION" '.[] | select(.file_menu_position == $pos)' "$DPP_SUBMENU_JSON")
  fi

  # Return to main menu option check:
  if [ "$OPTION" == "$BACK_TO_MAIN_MENU_UP" ] || [ "$OPTION" == "$BACK_TO_MAIN_MENU_DOWN" ]; then
    unset DPP_SUBMENU_ACTIVE
    return 0
  fi

  # Return 1 if no match found:
  [ -z "$script" ] && return 1

  local script_name
  script_name=$(jq -r '.file_name' <<<"$script")

  local script_path="$DPP_PACKAGES_SCRIPTS_PATH/$script_name"

  # Execute do_work function from the script:
  bash "$script_path" do_work

  return 0
}
