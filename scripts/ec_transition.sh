#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# shellcheck source=../include/dts-environment.sh
source $DTS_ENV
# shellcheck source=../include/dts-functions.sh
source $DTS_FUNCS
# shellcheck source=../include/hal/dts-hal.sh
source $DTS_HAL

board_config() {
  case "$SYSTEM_VENDOR" in
  "Notebook")
    case "$SYSTEM_MODEL" in
    "NS50_70MU")
      HAVE_EC="true"
      NEED_EC_RESET="true"
      COMPATIBLE_EC_FW_VERSION="2022-08-31_cbff21b"
      EC_HASH="d1001465cea74a550914c14f0c8f901b14827a3b5fa0b612ae6d11594ac2b405  /tmp/ecupdate.rom"
      BIOS_HASH="d4c30660c53bac505997de30b9eac4c5ac15f3212c62366730dc2ca3974bba18  /tmp/biosupdate.rom"
      PROGRAMMER_BIOS="internal"
      PROGRAMMER_EC="ite_ec"
      BIOS_LINK="https://cloud.3mdeb.com/index.php/s/SKpqSNzfFNY7AbK/download"
      EC_LINK="https://cloud.3mdeb.com/index.php/s/GK2KbXaYprkCCWM/download"
      ;;
    "NV4XMB,ME,MZ")
      HAVE_EC="true"
      NEED_EC_RESET="true"
      COMPATIBLE_EC_FW_VERSION="2022-10-07_c662165"
      EC_HASH="7a75fd9afd81012f7c1485cc335298979509e5929d931d898465fbddb4ce105c  /tmp/ecupdate.rom"
      BIOS_HASH="7271b638c87cba658162931f55bdaa6987eb5b0555075ce8e2297a79a505c8b0  /tmp/biosupdate.rom"
      PROGRAMMER_BIOS="internal:boardmismatch=force"
      PROGRAMMER_EC="ite_ec:boardmismatch=force,romsize=128K,autoload=disable"
      BIOS_LINK="https://cloud.3mdeb.com/index.php/s/3cjkJSWBzPfb5SP/download"
      EC_LINK="https://cloud.3mdeb.com/index.php/s/9S5Tmy6kwFjpcNm/download"
      ;;
    *)
      error_exit "Board model $SYSTEM_MODEL is currently not supported"
      ;;
    esac
    ;;
  *)
    error_exit "Board vendor: $SYSTEM_VENDOR is currently not supported"
    ;;
  esac
}

download_files() {
  wait_for_network_connection
  wget -O $EC_UPDATE_FILE $EC_LINK
  error_check "Cannot download EC update file. Aborting..."
  wget -O $BIOS_UPDATE_FILE $BIOS_LINK
  error_check "Cannot download FW update file. Aborting..."
  echo "Successfully downloaded EC and FW files."
}

update_ec() {
  sha256sum --check <(echo "$EC_HASH")
  error_check "Failed to download EC firmware update"

  echo "Updating EC..."
  $FLASHROM -p ${PROGRAMMER_EC} -w /tmp/ecupdate.rom >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
  error_check "Failed to update EC firmware"

  echo "Successfully updated EC firmware"
}

install() {
  sha256sum --check <(echo "$BIOS_HASH")
  error_check "Failed to verify Dasharo firmware"

  if [ "$HAVE_EC" == "true" ]; then
    _ec_fw_version=$($FLASHROM get_ec_firm_version_mock -p ${PROGRAMMER_EC} | grep "Mainboard EC Version" | tr -d ' ' | cut -d ':' -f 2)

    if [ "$_ec_fw_version" != "$COMPATIBLE_EC_FW_VERSION" ]; then
      echo "EC version: $_ec_fw_version is not supported, update required"
      update_ec
    fi
  fi

  echo "Installing Dasharo firmware..."
  $FLASHROM -p ${PROGRAMMER_BIOS} --ifd -i bios -w /tmp/biosupdate.rom >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
  error_check "Failed to install Dasharo firmware"

  echo "Successfully installed Dasharo firmware"

  echo "Powering off"
  sleep 1
  if [ "$NEED_EC_RESET" = "true" ]; then
    it5570_shutdown
  else
    ${POWEROFF}
  fi
}

usage() {
  echo "Usage:"
  echo "  $0 "
  exit 1
}

[ -z "$SYSTEM_VENDOR" ] && error_exit "SYSTEM_VENDOR not given"
[ -z "$SYSTEM_MODEL" ] && error_exit "SYSTEM_MODEL not given"

if check_for_opensource_firmware; then
  error_exit "Device has already Open Source Embedded Controller firmware, aborting..."
fi
board_config
download_files
install
