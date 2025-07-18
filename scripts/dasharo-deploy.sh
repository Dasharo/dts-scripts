#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Some variables (especially those with hashes, are being used by functions in
# dts-functions.sh only, shellcheck is unaware of them and marks them as
# unused.)
# shellcheck disable=SC2034

# shellcheck source=../include/dts-environment.sh
source $DTS_ENV
# shellcheck source=../include/dts-functions.sh
source $DTS_FUNCS
# shellcheck source=../include/hal/dts-hal.sh
source $DTS_HAL

[ -z "$SYSTEM_VENDOR" ] && error_exit "SYSTEM_VENDOR not given"
[ -z "$SYSTEM_MODEL" ] && error_exit "SYSTEM_MODEL not given"

# Variables used in this script:
# Currently following firmware versions are available: community, community_cap,
# dpp, dpp_cap, seabios, and heads:
declare FIRMWARE_VERSION
declare CAN_SWITCH_TO_HEADS
CMD="$1"
FUM="$2"

print_firm_access_warning() {
  # This function prints standard warning informing user that a specific DPP
  # firmware is available but he does not have access to it. Arguments: dpp,
  # dpp_cap, seabios, and heads:
  local _firm_type="$1"
  local _firm_type_print

  case $_firm_type in
  dpp)
    _firm_type_print="coreboot + UEFI"
    ;;
  dpp_cap)
    _firm_type_print="coreboot + UEFI via Capsule Update"
    ;;
  seabios)
    _firm_type_print="coreboot + SeaBIOS"
    ;;
  heads)
    _firm_type_print="coreboot + Heads"
    ;;
  *)
    return 1
    ;;
  esac

  # Just a new line:
  echo
  echo " Dasharo Pro Package version (${_firm_type_print}) is also available."
  echo " If you are interested, please visit"
  echo " https://shop.3mdeb.com/product-category/dasharo-pro-package/"
  # Just a new line:
  echo

  return 0
}

check_for_firmware_access() {
  # DPP credentials are being provided outside of this script, this script only
  # has to check whether the credentials give access to appropriate firmware. The
  # appropriate firmware are defined by FIRMWARE_VERSION variable.

  local _firm_ver_to_check
  _firm_ver_to_check=$1

  case ${_firm_ver_to_check} in
  community)
    # Always available.
    ;;
  community_cap)
    # Always available.
    ;;
  dpp)
    # This firmware type require user to provide creds:
    [ "$DPP_IS_LOGGED" == "true" ] || return 1

    mc find "${DPP_SERVER_USER_ALIAS}/${BIOS_LINK_DPP}" >/dev/null 2>>"$ERR_LOG_FILE"

    [ $? -ne 0 ] && return 1
    ;;
  dpp_cap)
    # This firmware type require user to provide creds:
    [ "$DPP_IS_LOGGED" == "true" ] || return 1

    mc find "${DPP_SERVER_USER_ALIAS}/${BIOS_LINK_DPP_CAP}" >/dev/null 2>>"$ERR_LOG_FILE"

    [ $? -ne 0 ] && return 1
    ;;
  seabios)
    # This firmware type require user to provide creds:
    [ "$DPP_IS_LOGGED" == "true" ] || return 1

    mc find "${DPP_SERVER_USER_ALIAS}/${BIOS_LINK_DPP_SEABIOS}" >/dev/null 2>>"$ERR_LOG_FILE"

    [ $? -ne 0 ] && return 1
    ;;
  heads)
    # This firmware type require user to provide creds:
    [ "$DPP_IS_LOGGED" == "true" ] || return 1

    mc find "${DPP_SERVER_USER_ALIAS}/${HEADS_LINK_DPP}" >/dev/null 2>>"$ERR_LOG_FILE"

    [ $? -ne 0 ] && return 1
    ;;
  esac

  return 0
}

ask_for_version() {
  # Available firmware versions are defined by FIRMWARE_VERSION variable. There
  # are community and DPP firmwares with UEFI Capsule Update support, but they are
  # for firmware updates only, but this function is being called during
  # installation, so no need to mention them here.
  local _option
  local _might_be_comm
  local _might_be_dpp
  local _might_be_seabios

  while :; do
    echo
    echo "Please, select Dasharo firmware version to install:"
    echo

    # Here we check if user has access to a certain version of Dasharo Firmware.
    # The check consists of two stages:
    # * does user platform support the firmware - BIOS_LINK_* variables are
    # being checked;
    # * does user has access rights to the blobs of the supported firmware - a
    # call to the server with binaries is done, to check if user can download
    # the blobs.
    if [ -n "$BIOS_LINK_COMM" ]; then
      if check_for_firmware_access community; then
        echo "  c) Community version"
        _might_be_comm="true"
      fi
    fi

    if [ -n "$BIOS_LINK_DPP" ]; then
      if check_for_firmware_access dpp; then
        echo "  d) DPP version (coreboot + UEFI)"
        _might_be_dpp="true"
      else
        print_firm_access_warning dpp
      fi
    fi

    if [ -n "$BIOS_LINK_DPP_SEABIOS" ]; then
      if check_for_firmware_access seabios; then
        echo "  s) DPP version (coreboot + SeaBIOS)"
        _might_be_seabios="true"
      else
        print_firm_access_warning seabios
      fi
    fi

    echo "  b) Back to main menu"
    echo
    read -r -p "Enter an option: " _option
    echo

    # In case of several Dasharo Firmware versions supported we leave the
    # decision to user:
    case ${_option} in
    c | C | comm | community | COMMUNITY | COMM | Community)
      if [ -n "$_might_be_comm" ]; then
        print_ok "Community (Coreboot + EDK2) version selected"
        FIRMWARE_VERSION="community"
        break
      fi
      ;;
    d | D | dpp | DPP | Dpp)
      if [ -n "$_might_be_dpp" ]; then
        print_ok "Subscription version (cooreboot + EDK2) selected"
        FIRMWARE_VERSION="dpp"
        break
      fi
      ;;
    s | S | sea | seabios | SeaBIOS)
      if [ -n "$_might_be_seabios" ]; then
        print_ok "Subscription version (coreboot + SeaBIOS) selected"
        FIRMWARE_VERSION="seabios"
        break
      fi
      ;;
    b | B)
      echo "Returning to main menu..."
      exit 0
      ;;
    *) ;;
    esac
  done

  return 0
}

choose_version() {
  # This function is used for determining Dasharo firmware update version and is
  # being used during updates only. We do not ask user to choose firmware update
  # versions compared to installation workflow (check ask_for_version function),
  # instead we have some priorities:
  # 1) Check if Dasharo Heads Firmware available, use it if yes;
  # 2) Check if Dasharo EDK2 Firmware available, use it if yes;
  # 3) Use Dasharo Community Firmware;
  #
  # Capsules have higher priority over simple binaries.
  #
  # TODO: Currently we do not have clear and concise update mechanisms (e.g. what
  # and when a specific firmware version can be used, how to handle revisions of
  # firmware).

  if [ "$HAVE_HEADS_FW" == "true" ]; then
    if check_for_firmware_access heads; then
      CAN_SWITCH_TO_HEADS="true"
      FIRMWARE_VERSION="heads"

      return 0
    else
      print_firm_access_warning heads
    fi
  fi

  if [ -n "$DASHARO_REL_VER_DPP_CAP" ]; then
    [ -z "$DASHARO_SUPPORT_CAP_FROM" ] && print_error "Variable DASHARO_SUPPORT_CAP_FROM must be set!"

    # Check, whether currently installed firmware supports Capsule Update (
    # check comments for DASHARO_SUPPORT_CAP_FROM in dts-environment.sh for more
    # inf):
    if compare_versions "$DASHARO_VERSION" "$DASHARO_SUPPORT_CAP_FROM"; then
      if check_for_firmware_access dpp_cap; then
        FIRMWARE_VERSION="dpp_cap"

        return 0
      else
        print_firm_access_warning dpp_cap
      fi
    fi
  fi

  if [ -n "$DASHARO_REL_VER_DPP_SEABIOS" ]; then
    tmp_rom=$(mktemp --dry-run)
    config=/tmp/config
    # get current firmware
    $FLASHROM flashrom_read_firm_mock -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} -r "$tmp_rom" >>"$FLASH_INFO_FILE" 2>>"$ERR_LOG_FILE"
    if [ -f "$tmp_rom" ]; then
      # extract config
      $CBFSTOOL read_bios_conffile_mock "$tmp_rom" extract -n config -f "$config" 2>>"$ERR_LOG_FILE"
      # check if current firmware is seabios, if yes then we can offer update
      if grep -q "CONFIG_PAYLOAD_SEABIOS=y" "$config"; then
        if check_for_firmware_access seabios; then
          FIRMWARE_VERSION="seabios"
          return $OK
        else
          print_firm_access_warning seabios
        fi
      fi
    else
      return $FAIL
    fi
  fi

  if [ -n "$DASHARO_REL_VER_DPP" ]; then
    if check_for_firmware_access dpp; then
      FIRMWARE_VERSION="dpp"

      return 0
    else
      print_firm_access_warning dpp
    fi
  fi

  if [ -n "$DASHARO_REL_VER_CAP" ]; then
    [ -z "$DASHARO_SUPPORT_CAP_FROM" ] && print_error "Variable DASHARO_SUPPORT_CAP_FROM must be set!"

    # Check, whether currently installed firmware supports Capsule Update (
    # check comments for DASHARO_SUPPORT_CAP_FROM in dts-environment.sh for more
    # inf):
    if compare_versions "$DASHARO_VERSION" "$DASHARO_SUPPORT_CAP_FROM"; then
      FIRMWARE_VERSION="community_cap"

      return 0
    fi
  fi

  # Last resort:
  FIRMWARE_VERSION="community"

  return 0
}

prepare_env() {
  # This function sets all needed variables after user have answered all needed
  # questions and before this script does any work.
  local _prepare_for
  _prepare_for="$1"

  # If firmware is being installed - user should choose what to install, if
  # firmware is being updated - final version is being chosen automatically
  if [ "$_prepare_for" == "update" ]; then
    choose_version
  elif [ "$_prepare_for" == "install" ]; then
    ask_for_version
  fi

  # This is the key variable for this function, should be set either by
  # choose_version or by ask_for_version:
  if [ -z "$FIRMWARE_VERSION" ]; then
    return 1
  fi

  # When board_config returns, we have a set of *_LINK_* variables holding links
  # to artifacts for our board. Now we need to decide which links to use (some
  # platforms may support several firmware types). The links being used are
  # determined bising on FIRMWARE_VERSION:
  if [ "$FIRMWARE_VERSION" == "community" ]; then
    BIOS_LINK=$BIOS_LINK_COMM
    BIOS_HASH_LINK=$BIOS_HASH_LINK_COMM
    BIOS_SIGN_LINK=$BIOS_SIGN_LINK_COMM

    UPDATE_VERSION="$DASHARO_REL_VER"

    # Check EC link additionally, not all platforms have Embedded Controllers:
    if [ -n "$EC_LINK_COMM" ]; then
      EC_LINK=$EC_LINK_COMM
      EC_HASH_LINK=$EC_HASH_LINK_COMM
      EC_SIGN_LINK=$EC_SIGN_LINK_COMM
    fi

    return 0
  elif [ "$FIRMWARE_VERSION" == "community_cap" ]; then
    BIOS_LINK=$BIOS_LINK_COMM_CAP
    BIOS_HASH_LINK=$BIOS_HASH_LINK_COMM_CAP
    BIOS_SIGN_LINK=$BIOS_SIGN_LINK_COMM_CAP

    UPDATE_VERSION="$DASHARO_REL_VER_CAP"

    # Check EC link additionally, not all platforms have Embedded Controllers:
    if [ -n "$EC_LINK_COMM_CAP" ]; then
      EC_LINK=$EC_LINK_COMM_CAP
      EC_HASH_LINK=$EC_HASH_LINK_COMM_CAP
      EC_SIGN_LINK=$EC_SIGN_LINK_COMM_CAP
    fi

    return 0
  elif [ "$FIRMWARE_VERSION" == "dpp" ]; then
    BIOS_LINK=$BIOS_LINK_DPP
    BIOS_HASH_LINK=$BIOS_HASH_LINK_DPP
    BIOS_SIGN_LINK=$BIOS_SIGN_LINK_DPP

    UPDATE_VERSION="$DASHARO_REL_VER_DPP"

    # Check EC link additionally, not all platforms have Embedded Controllers:
    if [ -n "$EC_LINK_DPP" ]; then
      EC_LINK=$EC_LINK_DPP
      EC_HASH_LINK=$EC_HASH_LINK_DPP
      EC_SIGN_LINK=$EC_SIGN_LINK_DPP
    fi

    return 0
  elif [ "$FIRMWARE_VERSION" == "dpp_cap" ]; then
    BIOS_LINK=$BIOS_LINK_DPP_CAP
    BIOS_HASH_LINK=$BIOS_HASH_LINK_DPP_CAP
    BIOS_SIGN_LINK=$BIOS_SIGN_LINK_DPP_CAP

    UPDATE_VERSION="$DASHARO_REL_VER_DPP_CAP"

    # Check EC link additionally, not all platforms have Embedded Controllers:
    if [ -n "$EC_LINK_DPP_CAP" ]; then
      EC_LINK=$EC_LINK_DPP_CAP
      EC_HASH_LINK=$EC_HASH_LINK_DPP_CAP
      EC_SIGN_LINK=$EC_SIGN_LINK_DPP_CAP
    fi

    return 0
  elif [ "$FIRMWARE_VERSION" == "seabios" ]; then
    BIOS_LINK=$BIOS_LINK_DPP_SEABIOS
    BIOS_HASH_LINK=$BIOS_HASH_LINK_DPP_SEABIOS
    BIOS_SIGN_LINK=$BIOS_SIGN_LINK_DPP_SEABIOS
    UPDATE_VERSION="$DASHARO_REL_VER_DPP_SEABIOS"

    return 0
  elif [ "$FIRMWARE_VERSION" == "heads" ]; then
    handle_fw_switching "$CAN_SWITCH_TO_HEADS"
    # If the user chose not to update to heads, allow them to try another
    # version
    ret_code=$?
    if [ $ret_code -eq $CANCEL ]; then
      HAVE_HEADS_FW="false"
      prepare_env $_prepare_for
    elif [ $ret_code -eq 0 ]; then
      return 0
    fi
  fi

  # Must not get here. If it gets here - the above variables are empty and
  # script will not be able to continue.
  return 1
}

display_warning() {
  # This function shows user some inf. about platform and binaries and asks if the
  # deployment process should be continued.
  local _option

  while :; do
    echo
    print_warning "Please verify detected hardware!"
    echo

    if [ -n "$SYSTEM_VENDOR" ]; then
      echo "Board vendor: $SYSTEM_VENDOR"
    fi
    if [ -n "$SYSTEM_MODEL" ]; then
      echo "System model: $SYSTEM_MODEL"
    fi
    if [ -n "$BOARD_MODEL" ]; then
      echo "Board model: $BOARD_MODEL"
    fi

    echo
    read -r -p "Does it match your actual specification? (Y|n) " _option
    echo

    case ${_option} in
    "" | yes | y | Y | Yes | YES)
      break
      ;;
    n | N | no | NO | No)
      echo "Returning to main menu..."
      exit 0
      ;;
    *) ;;
    esac
  done

  while :; do
    echo "Following firmware will be used to deploy Dasharo:"

    if [ -n "$BIOS_LINK" ]; then
      local _bios_hash
      _bios_hash="$(cat $BIOS_HASH_FILE | cut -d ' ' -f 1)"
      echo "Dasharo BIOS firmware:"
      echo "  - link: $BIOS_LINK"
      echo "  - hash: $_bios_hash"
    fi

    if [ -n "$EC_LINK" ]; then
      local _ec_hash
      _ec_hash="$(cat $EC_HASH_FILE | cut -d ' ' -f 1)"
      echo "Dasharo EC firmware:"
      echo "  - link: $EC_LINK"
      echo "  - hash: $_ec_hash"
    fi

    echo
    echo "You can learn more about this release on: https://docs.dasharo.com/"

    if ! check_if_dasharo &&
      [ "$CAN_INSTALL_BIOS" = "false" ] &&
      [ "$HAVE_EC" = "true" ]; then
      print_warning "$SYSTEM_VENDOR $SYSTEM_MODEL supports only EC firmware deployment!"
      print_warning "Dasharo BIOS will have to be flashed manually. More on:"
      print_warning "https://docs.dasharo.com/unified/novacustom/initial-deployment/"
    fi

    echo
    read -r -p "Do you want to deploy this Dasharo Firmware on your platform (Y|n) " _option
    echo

    case ${_option} in
    "" | yes | y | Y | Yes | YES)
      break
      ;;
    n | N | no | NO | No)
      echo "Returning to main menu..."
      exit 0
      ;;
    *) ;;
    esac
  done

  return 0
}

backup() {
  rm -rf "$FW_BACKUP_DIR"
  mkdir -p "$FW_BACKUP_DIR"

  echo "Backing up BIOS firmware and store it locally..."
  echo "Remember that firmware is also backed up in HCL report."
  check_intel_regions
  if [ $BOARD_HAS_FD_REGION -eq 1 ]; then
    # Use safe defaults. Descriptor may contain additional regions not detected
    # by flashrom and will return failure when attempted to be read. BIOS and
    # Flash descriptor regions should always be readable. If not, then we have
    # some ugly case, hard to deal with.
    FLASHROM_ADD_OPT_READ="--ifd -i fd -i bios"
    if [ $BOARD_HAS_ME_REGION -eq 1 ] && [ $BOARD_ME_REGION_LOCKED -eq 0 ]; then
      # ME region is not locked, read it as well
      FLASHROM_ADD_OPT_READ+=" -i me"
    fi
    if [ $BOARD_HAS_GBE_REGION -eq 1 ] && [ $BOARD_GBE_REGION_LOCKED -eq 0 ]; then
      # GBE region is present and not locked, read it as well
      FLASHROM_ADD_OPT_READ+=" -i gbe"
    fi
  else
    # No descriptor, probably safe to read everything
    FLASHROM_ADD_OPT_READ=""
  fi
  $FLASHROM read_firm_mock -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} -r "${FW_BACKUP_DIR}"/rom.bin ${FLASHROM_ADD_OPT_READ} >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
  error_check "Failed to read BIOS firmware backup"

  if [ "$HAVE_EC" == "true" ]; then
    if check_for_opensource_firmware; then
      echo "Device has already Open Source Embedded Controller firmware, do not backup EC..."
    else
      echo "Backing up EC firmware..."
      $FLASHROM read_firm_mock -p "$PROGRAMMER_EC" ${FLASH_CHIP_SELECT} -r "${FW_BACKUP_DIR}"/ec.bin >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
      error_check "Failed to read EC firmware backup"
    fi
  fi

  echo "Saving backup to: $FW_BACKUP_TAR"
  tar --gzip -cf "$FW_BACKUP_TAR" "$FW_BACKUP_DIR"
  error_check "Failed to create firmware backup archive"
  rm -rf "${FW_BACKUP_DIR}"

  echo "Successfully backed up firmware locally at: $FW_BACKUP_TAR"
}

romhole_migration() {
  $CBFSTOOL layout_mock $BIOS_UPDATE_FILE layout -w | grep -q "ROMHOLE" || return

  $FLASHROM read_firm_mock -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} -r /tmp/rom.bin --ifd -i bios >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
  error_check "Failed to read current firmware to migrate MSI ROMHOLE"
  if check_if_dasharo; then
    $CBFSTOOL layout_mock /tmp/rom.bin layout -w | grep -q "ROMHOLE" || return
    # This one is rather unlikely to fail, but just in case print a warning
    $CBFSTOOL read_romhole_mock /tmp/rom.bin read -r ROMHOLE -f /tmp/romhole.bin 2>>"$ERR_LOG_FILE"
    if [ $? -ne 0 ]; then
      print_warning "Failed to migrate MSI ROMHOLE, your platform's unique SMBIOS/DMI data may be lost"
      return
    fi
  else
    dd if=/tmp/rom.bin of=/tmp/romhole.bin skip=$((0x17C0000)) bs=128K count=1 iflag=skip_bytes >/dev/null 2>>"$ERR_LOG_FILE"
  fi

  $CBFSTOOL "$BIOS_UPDATE_FILE" write -r ROMHOLE -f /tmp/romhole.bin -u 2>>"$ERR_LOG_FILE"
}

smbios_migration() {
  echo -n "$($DMIDECODE dump_var_mock -s system-uuid)" >$SYSTEM_UUID_FILE
  echo -n "$($DMIDECODE dump_var_mock -s baseboard-serial-number)" >$SERIAL_NUMBER_FILE

  COREBOOT_SEC=$($CBFSTOOL layout_mock $BIOS_UPDATE_FILE layout -w | grep "COREBOOT")
  FW_MAIN_A_SEC=$($CBFSTOOL layout_mock $BIOS_UPDATE_FILE layout -w | grep "FW_MAIN_A")
  FW_MAIN_B_SEC=$($CBFSTOOL layout_mock $BIOS_UPDATE_FILE layout -w | grep "FW_MAIN_B")

  if [ -n "$COREBOOT_SEC" ]; then
    # if the migration can be done there for sure will be COREBOOT section
    echo "Beginning SMBIOS migration process..."
    echo "Migrate to COREBOOT section."
    $CBFSTOOL $BIOS_UPDATE_FILE add -f $SERIAL_NUMBER_FILE -n serial_number -t raw -r COREBOOT
    $CBFSTOOL $BIOS_UPDATE_FILE add -f $SYSTEM_UUID_FILE -n system_uuid -t raw -r COREBOOT
  fi

  if [ -n "$FW_MAIN_A_SEC" ]; then
    echo "Migrate to FW_MAIN_A section."
    $CBFSTOOL $BIOS_UPDATE_FILE expand -r FW_MAIN_A
    $CBFSTOOL $BIOS_UPDATE_FILE add -f $SERIAL_NUMBER_FILE -n serial_number -t raw -r FW_MAIN_A
    $CBFSTOOL $BIOS_UPDATE_FILE add -f $SYSTEM_UUID_FILE -n system_uuid -t raw -r FW_MAIN_A
    $CBFSTOOL $BIOS_UPDATE_FILE truncate -r FW_MAIN_A
  fi

  if [ -n "$FW_MAIN_B_SEC" ]; then
    echo "Migrate to FW_MAIN_B section."
    $CBFSTOOL $BIOS_UPDATE_FILE expand -r FW_MAIN_B
    $CBFSTOOL $BIOS_UPDATE_FILE add -f $SERIAL_NUMBER_FILE -n serial_number -t raw -r FW_MAIN_B
    $CBFSTOOL $BIOS_UPDATE_FILE add -f $SYSTEM_UUID_FILE -n system_uuid -t raw -r FW_MAIN_B
    $CBFSTOOL $BIOS_UPDATE_FILE truncate -r FW_MAIN_B
  fi
}

smmstore_migration() {
  echo -n "Backing up firmware configuration... "
  $FLASHROM read_firm_mock -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} -r /tmp/dasharo_dump.rom ${FLASHROM_ADD_OPT_READ} --fmap -i FMAP -i SMMSTORE >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
  $CBFSTOOL read_smmstore_mock /tmp/dasharo_dump.rom read -r SMMSTORE -f /tmp/smmstore.bin >>$ERR_LOG_FILE 2>&1 ||
    print_warning "Failed! Default settings will be used."
  $CBFSTOOL "$BIOS_UPDATE_FILE" write -r SMMSTORE -f /tmp/smmstore.bin -u >>$ERR_LOG_FILE 2>&1 ||
    print_warning "Failed! Default settings will be used."
  print_ok Done.
}

bootsplash_migration() {
  $FLASHROM read_firm_mock -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} -r /tmp/dasharo_dump.rom ${FLASHROM_ADD_OPT_READ} --fmap -i FMAP -i BOOTSPLASH >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
  # If no custom logo, return from bootsplash_migration early and don't show
  # unnecessary messages
  $CBFSTOOL /tmp/dasharo_dump.rom extract -r BOOTSPLASH -n logo.bmp -f /tmp/logo.bmp >>$ERR_LOG_FILE 2>&1 || return 1
  echo -n "Backing up custom boot logo... "
  $DCU logo $BIOS_UPDATE_FILE -l /tmp/logo.bmp >>$ERR_LOG_FILE 2>&1 ||
    print_warning "Failed! Default boot splash will be used." || return 1
  print_ok Done.
}

resign_binary() {
  if [ "$HAVE_VBOOT" -eq 0 ]; then
    download_keys
    sign_firmware.sh $BIOS_UPDATE_FILE $KEYS_DIR $RESIGNED_BIOS_UPDATE_FILE
    error_check "Cannot resign binary file. Please, make sure if you have proper keys. Aborting..."
    BIOS_UPDATE_FILE="$RESIGNED_BIOS_UPDATE_FILE"
  fi
}

check_vboot_keys() {
  if [ "$HAVE_VBOOT" -eq 0 ]; then
    # If we flash whole BIOS region, no need to check if keys match
    grep -q "\--ifd" <<<"$FLASHROM_ADD_OPT_UPDATE" && grep -q "\-i bios" <<<"$FLASHROM_ADD_OPT_UPDATE" && return
    # No FMAP flashing? Also skip
    grep -q "\--fmap" <<<"$FLASHROM_ADD_OPT_UPDATE" || return

    BINARY_KEYS=$(CBFSTOOL=$(which cbfstool) $FUTILITY dump_vboot_keys show $BIOS_UPDATE_FILE | grep -i 'key sha1sum')

    if [ $BOARD_HAS_FD_REGION -eq 0 ]; then
      FLASHROM_ADD_OPT_READ=""
    else
      FLASHROM_ADD_OPT_READ="--ifd -i bios"
    fi
    echo "Checking vboot keys."
    $FLASHROM read_firm_mock -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} ${FLASHROM_ADD_OPT_READ} -r $BIOS_DUMP_FILE >/dev/null 2>>"$ERR_LOG_FILE"
    if [ $? -eq 0 ] && [ -f $BIOS_DUMP_FILE ]; then
      FLASH_KEYS=$(CBFSTOOL=$(which cbfstool) $FUTILITY dump_vboot_keys show $BIOS_DUMP_FILE | grep -i 'key sha1sum')
      diff <(echo "$BINARY_KEYS") <(echo "$FLASH_KEYS") >/dev/null 2>>"$ERR_LOG_FILE"
      # If keys are different we must additionally flash at least GBB region as well
      if [ $? -ne 0 ]; then
        FLASHROM_ADD_OPT_UPDATE+=" -i GBB"
      fi
    fi
  fi
}

blob_transmission() {
  echo "Extracting the UEFI image from BIOS update"
  wget -O "$DBT_BIOS_UPDATE_FILENAME" --user-agent='Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)' "$DBT_BIOS_UPDATE_URL" >>$ERR_LOG_FILE 2>&1
  error_file_check "$DBT_BIOS_UPDATE_FILENAME" "Failed to download BIOS for $SYSTEM_MODEL. Please make sure Ethernet cable is connected and try again."

  sha256sum --check <(echo "$DBT_BIOS_UPDATE_HASH")
  error_check "Failed SHA-256 sum check on the downloaded BIOS for $SYSTEM_MODEL"

  binwalk --run-as=root -e "$DBT_BIOS_UPDATE_FILENAME" -C /tmp >>$ERR_LOG_FILE 2>&1
  error_file_check "$DBT_UEFI_IMAGE" "Failed to extract UEFI image from BIOS update"

  uefi-firmware-parser -e "$DBT_UEFI_IMAGE" -O >>$ERR_LOG_FILE 2>&1

  if [ -n "$SINIT_ACM_FILENAME" ] && [ -n "$SINIT_ACM_URL" ]; then
    echo "Downloading the Intel SINIT ACM"
    wget -O "$SINIT_ACM_FILENAME" "$SINIT_ACM_URL" >>$ERR_LOG_FILE 2>&1
    error_file_check "$SINIT_ACM_FILENAME" "Failed to download Intel SINIT ACM. Please make sure Ethernet cable is connected and try again."

    echo "Downloading the Intel SINIT ACM checksum"
    wget -O "$SINIT_ACM_HASH_FILENAME" "$SINIT_ACM_HASH_URL" >>$ERR_LOG_FILE 2>&1
    error_file_check "$SINIT_ACM_HASH_FILENAME" "Failed to download Intel SINIT ACM checksum. Please make sure Ethernet cable is connected and try again."

    sha256sum --check "$SINIT_ACM_HASH_FILENAME"
    error_check "Failed SHA-256 sum check on the downloaded Intel SINIT ACM."

    cp "$SINIT_ACM_FILENAME" "$SINIT_ACM"
  fi

  echo "Beginning Dasharo Blobs Transmission process..."

  if [ -n "$SCH5545_FW" ]; then
    error_file_check "$SCH5545_FW" "Failed to find SCH5545 EC firmware binary."
    echo -n "Adding SCH5545 EC firmware..."
    $CBFSTOOL "$BIOS_UPDATE_FILE" add -f "$SCH5545_FW" -n sch5545_ecfw.bin -t raw
    print_ok "Done"
  fi

  if [ -n "$ACM_BIN" ]; then
    error_file_check "$ACM_BIN" "Failed to find BIOS ACM binary."
    echo -n "Adding BIOS ACM..."
    $CBFSTOOL "$BIOS_UPDATE_FILE" add -f "$ACM_BIN" -n txt_bios_acm.bin -t raw -a 0x20000
    print_ok "Done"
  fi

  if [ -n "$SINIT_ACM" ]; then
    error_file_check "$SINIT_ACM" "Failed to find Intel SINIT ACM binary."
    echo -n "Adding SINIT ACM..."
    $CBFSTOOL "$BIOS_UPDATE_FILE" add -f "$SINIT_ACM" -n txt_sinit_acm.bin -t raw -c lzma
    print_ok "Done"
  fi
}

deploy_ec_firmware() {
  # This function deploys (installs or updates) downloaded EC firmware either UEFI
  # capsules (updates only) and binaries. Parameters: update, install.
  #
  # TODO: Currently we have here flashrom parameters configuration code, this
  # should be done before this function is called, so as to place here only
  # deployment-related code. Ideally the deploying calls would look like this:
  #
  # $DEPLOY_COMMAND $DEPLOY_ARGS &>> $LOGS_FILE
  local _mode
  _mode="$1"

  if [ "$_mode" == "update" ]; then
    echo "Updating EC..."

    # The EC firmware could be updated in two ways: via UEFI Capsule Update or
    # via binaries and flashrom:
    if [ "$FIRMWARE_VERSION" == "community_cap" ] || [ "$FIRMWARE_VERSION" == "dpp_cap" ]; then
      # Linux Kernel driver is responsible for handling UEFI Capsule Updates, so
      # the capsule should be fed to a specific device:
      $CAP_UPD_TOOL "$EC_UPDATE_FILE"
      # Return after updating. The below code is for flashrom updates (using
      # binaries) only
      return 0
    fi

    echo "Updating Embedded Controller firmware. Your computer will power off automatically when done."

    # Following command will reset device, so the function will not quit:
    $DASHARO_ECTOOL flash "$EC_UPDATE_FILE" &>>$ERR_LOG_FILE
    error_check "Failed to update EC firmware"

    return 0
  elif [ "$_mode" == "install" ]; then

    if check_for_opensource_firmware; then
      echo "Device has already Open Source Embedded Controller firmware, do not flash EC..."
    else
      _ec_fw_version=$($FLASHROM get_ec_firm_version_mock check -p "$PROGRAMMER_EC" ${FLASH_CHIP_SELECT} | grep "Mainboard EC Version" | tr -d ' ' | cut -d ':' -f 2)

      if [ "$_ec_fw_version" != "$COMPATIBLE_EC_FW_VERSION" ]; then
        echo "Installing EC..."
        $FLASHROM -p "$PROGRAMMER_EC" ${FLASH_CHIP_SELECT} -w "$EC_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
        error_check "Failed to install Dasharo EC firmware"
        print_ok "Successfully installed Dasharo EC firmware"
      fi
    fi

    return 0
  fi

  # Must not get here:
  return 1
}

firmware_pre_updating_routine() {
  # This function only separates some code from deployment code, so to make clear
  # where is deployment code, and what should be executed before it:
  check_flash_lock

  if [ "$HAVE_EC" == "true" ]; then
    check_for_opensource_firmware
    error_check "Device does not have Dasharo EC firmware - cannot continue update!"
  fi

  if [ "$NEED_SMMSTORE_MIGRATION" = "true" ]; then
    smmstore_migration
  fi

  if [ "$NEED_BOOTSPLASH_MIGRATION" = "true" ]; then
    bootsplash_migration
  fi

  $CBFSTOOL read_bios_conffile_mock "$BIOS_UPDATE_FILE" extract -r COREBOOT -n config -f "$BIOS_UPDATE_CONFIG_FILE"
  grep -q "CONFIG_VBOOT=y" "$BIOS_UPDATE_CONFIG_FILE"
  HAVE_VBOOT="$?"

  check_intel_regions
  check_blobs_in_binary $BIOS_UPDATE_FILE
  check_if_me_disabled
  set_flashrom_update_params $BIOS_UPDATE_FILE
  check_vboot_keys

  return 0
}

firmware_pre_installation_routine() {
  # This function only separates some code from deployment code, so to make clear
  # where is deployment code, and what should be executed before it:
  check_flash_lock
  check_intel_regions
  check_blobs_in_binary $BIOS_UPDATE_FILE
  check_if_me_disabled
  set_intel_regions_update_params "-N --ifd -i bios"

  $CBFSTOOL read_bios_conffile_mock "$BIOS_UPDATE_FILE" extract -r COREBOOT -n config -f "$BIOS_UPDATE_CONFIG_FILE"
  grep -q "CONFIG_VBOOT=y" "$BIOS_UPDATE_CONFIG_FILE"
  HAVE_VBOOT="$?"

  if [ "$NEED_ROMHOLE_MIGRATION" = "true" ]; then
    romhole_migration
  fi

  if [ "$NEED_BOOTSPLASH_MIGRATION" = "true" ]; then
    bootsplash_migration
  fi

  if [ "$NEED_SMBIOS_MIGRATION" = "true" ]; then
    smbios_migration
    resign_binary
  fi

  if [ "$NEED_BLOB_TRANSMISSION" = "true" ]; then
    blob_transmission
  fi

  return 0
}

deploy_firmware() {
  # This function deploys (installs or updates) downloaded firmware either UEFI
  # capsules (updates only) or binaries. Parameters: update, install.
  #
  # TODO: Currently we have here flashrom parameters configuration code, this
  # should be done before this function is called, so as to place here only
  # deployment-related code. Ideally the deploying calls would look like this:
  #
  # $DEPLOY_COMMAND $DEPLOY_ARGS &>> $LOGS_FILE
  local _mode
  _mode="$1"

  if [ "$_mode" == "update" ]; then
    echo "Updating Dasharo firmware..."
    print_warning "This may take several minutes. Please be patient and do not"
    print_warning "power off your computer or touch the keyboard!"

    # Firstly we need to check, whether it is possible to use UEFI Capsule
    # Update, this is the preferred way of updating:
    if [ "$FIRMWARE_VERSION" == "community_cap" ] || [ "$FIRMWARE_VERSION" == "dpp_cap" ]; then
      # Linux Kernel driver is responsible for handling UEFI Capsule Updates, so
      # the capsule should be fed to a specific device:
      $CAP_UPD_TOOL "$BIOS_UPDATE_FILE"
      # Return after updating. The below code is for flashrom updates (using
      # binaries) only.
      return 0
    fi

    # Pre-update routine for UEFI Capsule Update is done by drivers and the
    # capsule itself, so the routine is required only for flashrom updates:
    firmware_pre_updating_routine

    # FLASHROM_ADD_OPT_UPDATE_OVERRIDE takes priority over auto-detected update params.
    # It set only by platform-specific and firmware version-specific conditions
    if [ -n "$FLASHROM_ADD_OPT_UPDATE_OVERRIDE" ]; then
      # To standardize the operation of the FLASHROM_ADD_OPT_UPDATE_OVERRIDE flag,
      # by default it contains only the bios section, below we verify the
      # downloaded binary and add more sections when they were detected after
      # using the `check_blobs_in_binary` function.
      set_intel_regions_update_params "$FLASHROM_ADD_OPT_UPDATE_OVERRIDE"
      FLASHROM_ADD_OPT_UPDATE_OVERRIDE="$FLASHROM_ADD_OPT_REGIONS"
      $FLASHROM -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} ${FLASHROM_ADD_OPT_UPDATE_OVERRIDE} -w "$BIOS_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
      error_check "Failed to update Dasharo firmware"
    else
      set_intel_regions_update_params "-N --ifd"
      $FLASHROM -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} ${FLASHROM_ADD_OPT_UPDATE} -w "$BIOS_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
      error_check "Failed to update Dasharo firmware"

      if [ $BINARY_HAS_RW_B -eq 0 ]; then
        echo "Updating second firmware partition..."
        $FLASHROM -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} --fmap -N -i RW_SECTION_B -w "$BIOS_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
        error_check "Failed to update second firmware partition"
      fi
    fi

    # We use FLASHROM_ADD_OPT_REGIONS for updating ME and IFD.
    # If FLASHROM_ADD_OPT_REGIONS remains the same after
    # set_intel_regions_update_params or is cleared, it means
    # we either cannot update any region, or were not allowed to,
    # or platform has no descriptor.
    if [ "$FLASHROM_ADD_OPT_REGIONS" != "-N --ifd" ] && [ "$FLASHROM_ADD_OPT_REGIONS" != "" ]; then
      UPDATE_STRING=""
      grep -q "\-i fd" <<<"$FLASHROM_ADD_OPT_REGIONS"
      UPDATE_IFD=$?
      grep -q "\-i me" <<<"$FLASHROM_ADD_OPT_REGIONS"
      UPDATE_ME=$?
      if [ $UPDATE_IFD -eq 0 ]; then
        UPDATE_STRING+="Flash Descriptor"
        if [ $UPDATE_ME -eq 0 ]; then
          UPDATE_STRING+=" and "
        fi
      fi
      if [ $UPDATE_ME -eq 0 ]; then
        UPDATE_STRING+="Management Engine"
      fi
      echo "Updating $UPDATE_STRING"
      $FLASHROM -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} ${FLASHROM_ADD_OPT_REGIONS} -w "$BIOS_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
      error_check "Failed to update $UPDATE_STRING"
    fi

    return 0
  elif [ "$_mode" == "install" ]; then
    firmware_pre_installation_routine

    echo "Installing Dasharo firmware..."
    # FIXME: It seems we do not have an easy way to add some flasrhom extra args
    # globally for specific platform and variant
    local _flashrom_extra_args=""
    if [ "${BIOS_LINK}" = "${BIOS_LINK_DPP_SEABIOS}" ]; then
      _flashrom_extra_args="--fmap -i COREBOOT"
    fi
    $FLASHROM -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} ${FLASHROM_ADD_OPT_REGIONS} -w "$BIOS_UPDATE_FILE" ${_flashrom_extra_args} >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
    error_check "Failed to install Dasharo firmware"
    print_ok "Successfully installed Dasharo firmware"

    return 0
  fi

  # Must not get here.
  return 1
}

install_workflow() {
  # Installation workflow. The installation of firmware is possible only via
  # flashrom, capsules cannot do the installation because they need initial
  # support inside firmware. The workflow steps are:
  # 1) Prepare system for installation (e.g. check connection);
  # 2) Prepare environment for installation (e.g. set all needed vars);
  # 3) Ask user are the changes that will be done ok;
  # 4) Do backup;
  # 5) Do the installation;
  # 6) Do some after-installation routine.
  sync_clocks

  # Verify that the device is not using battery as a power source:
  check_if_ac
  error_check "Firmware update process interrupted on user request."

  # Set all global variables needed for installation:
  prepare_env install

  # Download and verify firmware:
  if [ "$HAVE_EC" == "true" ]; then
    download_ec
    verify_artifacts ec
  fi
  if [ "$CAN_INSTALL_BIOS" == "true" ]; then
    download_bios
    verify_artifacts bios
  fi

  # Ask user for confirmation:
  display_warning

  backup

  # Deploy EC firmware
  if [ "$HAVE_EC" == "true" ]; then
    deploy_ec_firmware install
  fi

  # Deploy BIOS firmware
  if [ "$CAN_INSTALL_BIOS" == "true" ]; then
    deploy_firmware install
  fi

  # Post-installation routine:
  echo -n "Syncing disks... "
  sync
  echo "Done."

  send_dts_logs

  if [ "$NEED_EC_RESET" == "true" ]; then
    echo "The computer will shut down automatically in 5 seconds"
  else
    echo "The computer will reboot automatically in 5 seconds"
  fi
  sleep 0.5
  echo "Rebooting in 5s:"
  echo "5..."
  sleep 1
  echo "4..."
  sleep 1
  echo "3..."
  sleep 1
  echo "2..."
  sleep 1
  echo "1..."
  sleep 0.5
  echo "Rebooting"
  sleep 1
  if [ "$NEED_EC_RESET" == "true" ]; then
    it5570_shutdown
  else
    ${REBOOT}
  fi
}

update_workflow() {
  # Update workflow. Supported firmware formats: binary, UEFI capsule. The
  # workflow steps are:
  # 1) Prepare system for update (e.g. check connection);
  # 2) Prepare environment for update (e.g. set all needed vars);
  # 3) Ask user are the changes that will be done ok;
  # 4) Do the updating;
  # 5) Do some after-updating routine.
  CAN_SWITCH_TO_HEADS="false"
  sync_clocks

  # Verify that the device is not using battery as a power source:
  check_if_ac
  error_check "Firmware update process interrupted on user request."

  # Set all global variables needed for installation:
  prepare_env update

  if [ -z "$UPDATE_VERSION" ]; then
    error_exit "No update available for your machine"
  fi

  print_ok "Current Dasharo version: $DASHARO_VERSION"

  if [ "$CAN_SWITCH_TO_HEADS" = "true" ] || [ "$DASHARO_FLAVOR" == "Dasharo (coreboot+heads)" ]; then
    print_ok "Latest available Dasharo version for your subscription: $UPDATE_VERSION (coreboot+Heads)"
  else
    print_ok "Latest available Dasharo version for your subscription: $UPDATE_VERSION"
    compare_versions $DASHARO_VERSION $UPDATE_VERSION
    if [ $? -ne 1 ]; then
      error_exit "No update available for your machine" $CANCEL
    fi
  fi

  # TODO: It is not a good practice to do some target specific work in the code
  # of a scallable product, this should be handled in a more scallable way:
  if [[ "$UPDATE_VERSION" == "1.1.1" &&
    ("$BOARD_MODEL" == "PRO Z690-A WIFI DDR4(MS-7D25)" ||
    "$BOARD_MODEL" == "PRO Z690-A DDR4(MS-7D25)" ||
    "$BOARD_MODEL" == "PRO Z690-A (MS-7D25)" ||
    "$BOARD_MODEL" == "PRO Z690-A WIFI (MS-7D25)") ]]; then

    cpu_gen_check=$($LSCPU | grep -F "Model name" | grep -E "\-(13|14)[0-9]{3}" | wc -l)

    if [ $cpu_gen_check -ne 0 ]; then
      echo "You have a 13th gen or above CPU and are trying to flash Dasharo v1.1.1 on a MSI PRO Z690-A DDR4 or DDR5 board"
      echo "That version does not support gen 13 and above CPU. Therefore we cannot continue with flashing."
      error_exit "Aborting update process..."
    fi
  fi

  if [ "$HAVE_EC" == "true" ]; then
    download_ec
    verify_artifacts ec
  fi

  download_bios
  verify_artifacts bios

  # Warning must be displayed after the artifacts have been downloaded, because
  # we check their hashes inside display_warning function:
  if [ ! "$FUM" == "fum" ]; then
    display_warning
  fi

  deploy_firmware update

  # TODO: Could it be placed somewhere else?
  if [ ! -z "$SWITCHING_TO" ]; then
    # Any post-branch-switch messaging should go here
    case "$SWITCHING_TO" in
    "uefi")
      print_ok "Successfully switched to Dasharo UEFI firmware."
      print_warning "You may need to re-create boot manager entries!"
      ;;
    "heads")
      print_ok "Successfully switched to Dasharo Heads firmware."
      print_warning "On first boot you will see a warning about unsealing TOTP secrets."
      print_warning "This is expected. Run OEM Factory Reset / Re-Ownership to finish deploying Heads."
      ;;
    esac
    read -p "Press Enter to continue."
  else
    # Regular update flow
    print_ok "Successfully updated Dasharo firmware."
  fi

  send_dts_logs

  # Post update routine:
  if [ "$HAVE_EC" == "true" ]; then
    deploy_ec_firmware update
  fi

  echo -n "Syncing disks... "
  sync
  echo "Done."
  echo "The computer will reboot automatically in 5 seconds"
  sleep 0.5
  echo "Rebooting in 5s:"
  echo "5..."
  sleep 1
  echo "4..."
  sleep 1
  echo "3..."
  sleep 1
  echo "2..."
  sleep 1
  echo "1..."
  sleep 0.5
  echo "Rebooting"
  sleep 1
  ${REBOOT}
}

ask_for_version_transition() {
  # Copy of ask_for_transition, trimmed for only SeaBIOS -> UEFI
  local _option
  local _might_be_comm
  local _might_be_dpp

  while :; do
    echo
    echo "Please, select Dasharo firmware version to install:"
    echo

    # Here we check if user has access to a certain version of Dasharo Firmware.
    # The check consists of two stages:
    # * does user platform support the firmware - BIOS_LINK_* variables are
    # being checked;
    # * does user has access rights to the blobs of the supported firmware - a
    # call to the server with binaries is done, to check if user can download
    # the blobs.
    if [ -n "$BIOS_LINK_COMM" ]; then
      if check_for_firmware_access community; then
        echo "  c) Community version"
        _might_be_comm="true"
      fi
    fi

    if [ -n "$BIOS_LINK_DPP" ]; then
      if check_for_firmware_access dpp; then
        echo "  d) DPP version (coreboot + UEFI)"
        _might_be_dpp="true"
      else
        print_firm_access_warning dpp
      fi
    fi

    echo "  b) Back to main menu"
    echo
    read -r -p "Enter an option: " _option
    echo

    # In case of several Dasharo Firmware versions supported we leave the
    # decision to user:
    case ${_option} in
    c | C | comm | community | COMMUNITY | COMM | Community)
      if [ -n "$_might_be_comm" ]; then
        print_ok "Community (Coreboot + EDK2) version selected"
        FIRMWARE_VERSION="community"
        break
      fi
      ;;
    d | D | dpp | DPP | Dpp)
      if [ -n "$_might_be_dpp" ]; then
        print_ok "Subscription version (cooreboot + EDK2) selected"
        FIRMWARE_VERSION="dpp"
        break
      fi
      ;;
    b | B)
      echo "Returning to main menu..."
      exit $OK
      ;;
    *) ;;
    esac
  done

  return $OK
}

prepare_env_transition() {
  # copy of prepare_env but trimmed only for SeaBIOS -> UEFI transition

  ask_for_version_transition

  # This is the key variable for this function, should be set either by
  # choose_version or by ask_for_version:
  if [ -z "$FIRMWARE_VERSION" ]; then
    return $FAIL
  fi

  # When board_config returns, we have a set of *_LINK_* variables holding links
  # to artifacts for our board. Now we need to decide which links to use (some
  # platforms may support several firmware types). The links being used are
  # determined bising on FIRMWARE_VERSION:
  if [ "$FIRMWARE_VERSION" == "community" ]; then
    BIOS_LINK=$BIOS_LINK_COMM
    BIOS_HASH_LINK=$BIOS_HASH_LINK_COMM
    BIOS_SIGN_LINK=$BIOS_SIGN_LINK_COMM

    UPDATE_VERSION="$DASHARO_REL_VER"

    return $OK
  elif [ "$FIRMWARE_VERSION" == "dpp" ]; then
    BIOS_LINK=$BIOS_LINK_DPP
    BIOS_HASH_LINK=$BIOS_HASH_LINK_DPP
    BIOS_SIGN_LINK=$BIOS_SIGN_LINK_DPP

    UPDATE_VERSION="$DASHARO_REL_VER_DPP"

    return $OK
  fi

  # Must not get here. If it gets here - the above variables are empty and
  # script will not be able to continue.
  return $FAIL
}

transition_firmware() {
  # trimmed copy of deploy_firmware, modified only for transition
  firmware_pre_installation_routine

  echo "Transitioning Dasharo firmware..."
  # FIXME: It seems we do not have an easy way to add some flasrhom extra args
  # globally for specific platform and variant
  $FLASHROM -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} ${FLASHROM_ADD_OPT_REGIONS} -w "$BIOS_UPDATE_FILE" >>$FLASHROM_LOG_FILE 2>>"$ERR_LOG_FILE"
  error_check "Failed to transition Dasharo firmware"
  print_ok "Successfully transitioned Dasharo firmware"

  return $OK
}

transition_workflow() {
  # As of now it only targets SeaBIOS -> UEFI transition for PCEngines
  sync_clocks

  # Set all global variables needed for installation:
  prepare_env_transition

  if [ "$CAN_INSTALL_BIOS" == "true" ]; then
    download_bios
    verify_artifacts bios
  fi

  # Ask user for confirmation:
  display_warning

  # Deploy BIOS firmware
  if [ "$CAN_INSTALL_BIOS" == "true" ]; then
    transition_firmware
  fi

  # Post-installation routine:
  echo -n "Syncing disks... "
  sync
  echo "Done."

  send_dts_logs

  echo "The computer will reboot automatically in 5 seconds"
  sleep 0.5
  _sleep_delay=5
  echo "Rebooting in ${_sleep_delay} s:"
  for ((i = _sleep_delay; i > 0; --i)); do
    echo "${i}..."
    sleep 1
  done
  echo "Rebooting"
  sleep 1
  if [ "$NEED_EC_RESET" == "true" ]; then
    it5570_shutdown
  else
    ${REBOOT}
  fi
}

restore() {
  while :; do
    echo
    echo "Restoring firmware from HCL report."
    echo "Take note that this will only restore BIOS firmware, no EC."
    echo "Please select one of available options."

    echo "  1) Check for HCL report stored locally"
    if [ -n "${DPP_IS_LOGGED}" ]; then
      echo "  2) Check for HCL report stored on 3mdeb cloud"
    fi
    echo "  b) Back to main menu"
    echo
    read -r -p "Enter an option: " OPTION
    echo

    local network_dev=""
    local mac_addr=""
    local uuid_string=""

    # HCL report should be named as in dasharo-hcl-report so we can find
    # the package based on uuid saved in name, we need to check two options
    # with and without MAC address
    network_dev="$(ip route show default | head -1 | awk '/default/ {print $5}')"
    mac_addr="$(cat /sys/class/net/${network_dev}/address)"
    uuid_string="$(cat /sys/class/net/)"
    # if above gives error then there is no internet connection and first
    # part of uuid should be blank
    if [ ! $? -eq 0 ]; then
      uuid_string=""
    fi
    uuid_string="${mac_addr}_$($DMIDECODE dump_var_mock -s system-product-name)"
    uuid_string+="_$($DMIDECODE dump_var_mock -s system-manufacturer)"
    uuid="$(uuidgen -n @x500 -N $uuid_string -s)"

    case ${OPTION} in
    1)
      echo
      echo "Searching for HCL report on device..."

      HCL_REPORT_PACKAGE="$(find / -name "*$uuid*" | head -n1)"
      if [ ! -z $HCL_REPORT_PACKAGE ]; then
        tar -zxf "$HCL_REPORT_PACKAGE" -C /tmp
        echo "Restoring BIOS firmware..."
        if [ -f "/tmp/logs/rom.bin" ]; then
          print_ok "Found $HCL_REPORT_PACKAGE"
          read -p "Do you want to restore firmware from the given HCL report? [N/y] "
          case ${REPLY} in
          yes | y | Y | Yes | YES)
            # Ideally we would like to write the entire flash when restoring,
            # but in reality we may face locked or unaccessible regions.
            # To be on the safe side, flash whatever can be flashed by determining
            # what is writable.
            check_flash_lock
            check_intel_regions
            check_blobs_in_binary /tmp/logs/rom.bin
            check_if_me_disabled
            set_intel_regions_update_params "-N --ifd -i bios"
            $FLASHROM -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} ${FLASHROM_ADD_OPT_REGIONS} -w "/tmp/logs/rom.bin" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
            error_check "Failed to restore BIOS firmware! You can try one more time."
            print_ok "Successfully restored firmware"
            echo "Returning to main menu..."
            exit 0
            ;;
          *)
            echo "Returning to main menu..."
            exit 0
            ;;
          esac
        else
          print_error "Report does not have firmware backup!"
        fi
      else
        print_warning "No HCL report found, cannot restore firmware"
        echo "Returning to main menu..."
        exit 0
      fi
      ;;
    2)
      echo
      echo "Searching for HCL report on cloud..."

      ${CMD_CLOUD_LIST} $uuid
      error_check "Could not download HCL report from cloud."

      HCL_REPORT_PACKAGE="$(find / -name "*$uuid*" | head -n1)"
      tar -zxf "$HCL_REPORT_PACKAGE" -C /tmp
      echo "Restoring BIOS firmware..."
      if [ -f "/tmp/logs/rom.bin" ]; then
        # Ideally we would like to write the entire flash when restoring,
        # but in reality we may face locked or unaccessible regions.
        # To be on the safe side, flash whatever can be flashed by determining
        # what is writable.
        check_flash_lock
        check_intel_regions
        check_blobs_in_binary /tmp/logs/rom.bin
        check_if_me_disabled
        set_intel_regions_update_params "-N --ifd -i bios"
        $FLASHROM -p "$PROGRAMMER_BIOS" ${FLASH_CHIP_SELECT} ${FLASHROM_ADD_OPT_REGIONS} -w "/tmp/logs/rom.bin" >>$FLASHROM_LOG_FILE 2>>$ERR_LOG_FILE
        error_check "Failed to restore BIOS firmware! You can try one more time."
        print_ok "Successfully restored firmware"
      else
        print_error "Report does not have firmware backup!"
      fi
      ;;
    b | B)
      echo "Returning to main menu..."
      exit 0
      ;;
    *) ;;
    esac
  done
}

usage() {
  echo "Usage:"
  echo "  $0 install  - Install Dasharo on this device"
  echo "  $0 update   - Update Dasharo"
  echo "  $0 restore  - Restore from a previously saved backup"
}

if ! check_if_dasharo; then
  if ! can_install_dasharo; then
    error_exit "Dasharo cannot be installed on this platform"
  fi
fi

# For FUM we start in dasharo-deploy so we need to verify that we have internet
# connection to download shasums in board_config
if [ "$FUM" == "fum" ]; then
  wait_for_network_connection
fi

# flashrom does not support QEMU. TODO: this could be handled in a better way:
if [ "${SYSTEM_VENDOR}" != "QEMU" ] && [ "${SYSTEM_VENDOR}" != "Emulation" ]; then
  # Size of flashchip should be checked before board_config func. because the
  # func. assigns some configs based on the chip size detected for ASUS boards
  # (FIXME).
  check_flash_chip || error_exit "No supported chipset found, exit."
fi

board_config

if [ -n "$PLATFORM_SIGN_KEY" ]; then
  get_signing_keys
fi

case "$CMD" in
install)
  if check_if_dasharo; then
    error_exit "Dasharo Firmware is already installed. This script is only for\r
        initial deployment of Dasharo Firmware. Aborting..."
  fi
  if [ "$CAN_INSTALL_BIOS" == "false" ] && [ "$HAVE_EC" == "false" ]; then
    print_warning "Initial deployment via DTS isn't supported for this platform."
    print_warning "Visit https://docs.dasharo.com/variants/overview/ to see supported"
    print_warning "platforms and how to deploy Dasharo firmware."
    exit 2
  else
    install_workflow
  fi
  ;;
update)
  if [ "$FUM" == "fum" ]; then
    echo "Firmware Update Mode detected; proceed with automatic update in 5 seconds"
    echo "Updating in 5s:"
    echo "5..."
    sleep 1
    echo "4..."
    sleep 1
    echo "3..."
    sleep 1
    echo "2..."
    sleep 1
    echo "1..."
    sleep 0.5
  fi
  update_workflow
  ;;
restore)
  if ! check_if_dasharo; then
    error_exit "Dasharo Firmware is not installed. This script is only for\r
        restoring original firmware on platforms that runs Dasharo Firmware. Aborting..."
  fi
  restore
  ;;
transition)
  transition_workflow
  ;;
*)
  usage
  ;;
esac
