#!/usr/bin/env bash

################################################################################
# Helper functions used in this script:
################################################################################
parse_for_arg_return_next() {
  # parse_for_arg_return_next <search_for> <list_of_args>...
  # search <list_of_args> for <search_for> argument. If it's found output to
  # stdout argument after it, e.g.
  # parse_for_arg_return_next --file arg1 --param1 --file <file> --param2
  # should output <file>
  # Arguments:
  # 1. The argument you are searching for like -r for flashrom;
  # 2. Space-separated list of arguments to search in.
  local _arg="$1"
  shift

  while [[ $# -gt 0 ]]; do
    case $1 in
    "$_arg")
      [ -n "$2" ] && echo "$2"

      return 0
      ;;
    *)
      shift
      ;;
    esac
  done

  return 1
}

# Mocking part of DTS HAL. For format used for mo mocking functions check
# dts-hal.sh script and tool_wrapper func..

################################################################################
# Common mocking function
################################################################################
common_mock() {
  # This mocking function is being called for all cases where mocking is needed,
  # but the result of mocking function execution is not important.
  local _tool="$1"

  echo "${FUNCNAME[0]}: using ${_tool}..."

  return 0
}

dont_mock() {
  # Call original tool without mocking. Can be used if we want to call tool via
  # tool wrapper e.g. if we want to log used tool in generated profile
  local _tool="$1"
  shift

  "$_tool" "$@"
}

################################################################################
# flashrom
################################################################################
TEST_FLASH_LOCK="${TEST_FLASH_LOCK:-}"
TEST_BOARD_HAS_FD_REGION="${TEST_BOARD_HAS_FD_REGION:-true}"
TEST_BOARD_FD_REGION_RW="${TEST_BOARD_FD_REGION_RW:-true}"
TEST_BOARD_HAS_ME_REGION="${TEST_BOARD_HAS_ME_REGION:-true}"
TEST_BOARD_ME_REGION_RW="${TEST_BOARD_ME_REGION_RW:-true}"
TEST_BOARD_ME_REGION_LOCKED="${TEST_BOARD_ME_REGION_LOCKED:-}"
TEST_BOARD_HAS_GBE_REGION="${TEST_BOARD_HAS_GBE_REGION:-true}"
TEST_BOARD_GBE_REGION_RW="${TEST_BOARD_GBE_REGION_RW:-true}"
TEST_BOARD_GBE_REGION_LOCKED="${TEST_BOARD_GBE_REGION_LOCKED:-}"
TEST_COMPATIBLE_EC_VERSINO="${TEST_COMPATIBLE_EC_VERSINO:-}"
TEST_FLASH_CHIP_SIZE="${TEST_FLASH_CHIP_SIZE:-$((2 * 1024 * 1024))}"
TEST_INTERNAL_PROGRAMMER_CHIPNAME="${TEST_INTERNAL_PROGRAMMER_CHIPNAME:-}"
TEST_INTERNAL_MULTIPLE_DEFINITIONS="${TEST_INTERNAL_MULTIPLE_DEFINITIONS:-}"
TEST_BOARD_HAS_BOOTSPLASH="${TEST_BOARD_HAS_BOOTSPLASH:-true}"
TEST_LAYOUT_READ_SHOULD_FAIL="${TEST_LAYOUT_READ_SHOULD_FAIL:-false}"

flashrom_verify_internal_chip() {
  # if TEST_INTERNAL_MULTIPLE_DEFINITIONS is true then flashrom command
  # requires '-c' argument containing 'TEST_INTERNAL_PROGRAMMER_CHIPNAME'
  # otherwise it should return 1
  local used_chip

  if [[ "$(parse_for_arg_return_next -p "$@")" != internal* ]]; then
    return 0
  fi

  if [ "$TEST_INTERNAL_MULTIPLE_DEFINITIONS" = "true" ]; then
    if used_chip="$(parse_for_arg_return_next -c "$@")" && [ "$used_chip" = "$TEST_INTERNAL_PROGRAMMER_CHIPNAME" ]; then
      return 0
    else
      return 1
    fi
  fi
}

flashrom_check_flash_lock_mock() {
  # For flash lock testing, for more inf. check check_flash_lock func.:
  flashrom_verify_internal_chip "$@" || return 1
  if [ "$TEST_FLASH_LOCK" = "true" ]; then
    echo "PR0: Warning:.TEST is read-only" 1>&2
    echo "SMM protection is enabled" 1>&2

    return 1
  fi

  return 0
}

flashrom_flash_chip_name_mock() {
  # For flash chip name check emulation, for more inf. check check_flash_chip
  # func.:
  flashrom_verify_internal_chip "$@" || return 1
  echo "${TEST_INTERNAL_PROGRAMMER_CHIPNAME}"

  return 0
}

flashrom_flash_chip_size_mock() {
  # For flash chip size check emulation, for more inf. check check_flash_chip
  # func..
  flashrom_verify_internal_chip "$@" || return 1
  echo "$TEST_FLASH_CHIP_SIZE"

  return 0
}

flashrom_check_intel_regions_mock() {
  # For flash regions check emulation, for more inf. check check_intel_regions
  # func.:
  flashrom_verify_internal_chip "$@" || return 1
  if [ "$TEST_BOARD_HAS_FD_REGION" = "true" ]; then
    echo -n "Flash Descriptor region (0x00000000-0x00000fff)"

    if [ "$TEST_BOARD_FD_REGION_RW" = "true" ]; then
      echo " is read-write"
    else
      echo " is read-only"
    fi
  fi

  if [ "$TEST_BOARD_HAS_ME_REGION" = "true" ]; then
    echo -n "Management Engine region (0x00600000-0x00ffffff)"

    if [ "$TEST_BOARD_ME_REGION_RW" = "true" ]; then
      echo -n " is read-write"
    else
      echo -n " is read-only"
    fi

    [ "$TEST_BOARD_ME_REGION_LOCKED" = "true" ] && echo -n " and is locked"
    echo ""
  fi

  if [ "$TEST_BOARD_HAS_GBE_REGION" = "true" ]; then
    echo -n "Gigabit Ethernet region (0x00001000-0x00413fff)"

    if [ "$TEST_BOARD_GBE_REGION_RW" = "true" ]; then
      echo -n " is read-write"
    else
      echo -n " is read-only"
    fi

    [ "$TEST_BOARD_GBE_REGION_LOCKED" = "true" ] && echo -n " and is locked"
    echo ""
  fi

  return 0
}

flashrom_read_flash_layout_mock() {
  # For checking flash layout for further flashrom arguments selection, for more
  # inf. check set_flashrom_update_params function.
  #
  # TODO: this one can be deleted in future and replaced with read_firm_mock,
  # which will create a binary with needed bytes appropriately set.
  # For -r check flashrom man page:
  local _file_to_write_into
  flashrom_verify_internal_chip "$@" || return 1
  _file_to_write_into=$(parse_for_arg_return_next "-r" "$@")

  if [ "${TEST_LAYOUT_READ_SHOULD_FAIL}" = "true" ]; then
    return 1
  fi
  echo "Testing..." >"$_file_to_write_into"

  return 0
}

flashrom_read_firm_mock() {
  # Emulating dumping of the firmware the platform currently uses. Currently it is
  # writing into text file, that should be changed to binary instead (TODO).
  # For -r check flashrom man page:
  local _file_to_write_into
  flashrom_verify_internal_chip "$@" || return 1
  _file_to_write_into=$(parse_for_arg_return_next "-r" "$@")

  echo "Test flashrom read." >"$_file_to_write_into"

  return 0
}

flashrom_read_firm_bootsplash_mock() {
  # Emulating dumping bootsplash region
  local _file_to_write_into
  flashrom_verify_internal_chip "$@" || return 1
  _file_to_write_into=$(parse_for_arg_return_next "-r" "$@")

  if [[ "$TEST_FMAP_REGIONS" == *BOOTSPLASH* ]]; then
    echo "Test flashrom read." >"$_file_to_write_into"
  else
    return 1
  fi

  return 0
}

flashrom_get_ec_firm_version_mock() {
  # Emulating wrong EC firmware version, check deploy_ec_firmware func. and
  # ec_transition script for more inf.:
  if [ -n "$TEST_COMPATIBLE_EC_VERSION" ]; then
    echo "Mainboard EC Version: $COMPATIBLE_EC_FW_VERSION"
  else
    echo "Mainboard EC Version: 0000-00-00-0000000"
  fi

  return 0
}

################################################################################
# dasharo_ectool
################################################################################
TEST_USING_OPENSOURCE_EC_FIRM="${TEST_USING_OPENSOURCE_EC_FIRM:-}"
TEST_NOVACUSTOM_MODEL="${TEST_NOVACUSTOM_MODEL:-}"

dasharo_ectool_check_for_opensource_firm_mock() {
  # Emulating opensource EC firmware presence, check check_for_opensource_firmware
  # for more inf.:
  if [ "$TEST_USING_OPENSOURCE_EC_FIRM" = "true" ]; then
    return 0
  fi

  return 1
}

novacustom_check_sys_model_mock() {
  if [ -n "$TEST_NOVACUSTOM_MODEL" ]; then
    echo "Dasharo EC Tool Mock - Info Command"
    echo "-----------------------------------"
    echo "board: novacustom/$TEST_NOVACUSTOM_MODEL"
    echo "version: 0000-00-00_0000000"
    echo "-----------------------------------"

    return 0
  fi

  return 1
}

################################################################################
# dmidecode
################################################################################
TEST_SYSTEM_VENDOR="${TEST_SYSTEM_VENDOR:-}"
TEST_SYSTEM_MODEL="${TEST_SYSTEM_MODEL:-}"
TEST_BOARD_MODEL="${TEST_BOARD_MODEL:-}"
TEST_CPU_VERSION="${TEST_CPU_VERSION:-}"
TEST_BIOS_VENDOR="${TEST_BIOS_VENDOR:-}"
TEST_SYSTEM_UUID="${TEST_SYSTEM_UUID:-}"
TEST_BASEBOARD_SERIAL_NUMBER="${TEST_BASEBOARD_SERIAL_NUMBER:-}"

dmidecode_common_mock() {
  # Emulating dumping dmidecode inf.:
  echo "${FUNCNAME[0]}: using dmidecode..."

  return 0
}

dmidecode_dump_var_mock() {
  # Emulating dumping specific dmidecode fields, this is the place where the value
  # of the fields are being replaced by those defined by testsuite:
  local _option_to_read
  _option_to_read=$(parse_for_arg_return_next "-s" "$@")

  case "$_option_to_read" in
  system-manufacturer)

    [ -z "$TEST_SYSTEM_VENDOR" ] && return 0

    echo "$TEST_SYSTEM_VENDOR"
    ;;
  system-product-name)

    [ -z "$TEST_SYSTEM_MODEL" ] && return 0

    echo "$TEST_SYSTEM_MODEL"
    ;;
  baseboard-version)

    [ -z "$TEST_BOARD_MODEL" ] && return 0

    echo "$TEST_BOARD_MODEL"
    ;;
  baseboard-product-name)

    [ -z "$TEST_BOARD_MODEL" ] && return 0

    echo "$TEST_BOARD_MODEL"
    ;;
  processor-version)

    [ -z "$TEST_CPU_VERSION" ] && return 0

    echo "$TEST_CPU_VERSION"
    ;;
  bios-vendor)

    [ -z "$TEST_BIOS_VENDOR" ] && return 0

    echo "$TEST_BIOS_VENDOR"
    ;;
  bios-version)

    [ -z "$TEST_BIOS_VERSION" ] && return 0

    echo "$TEST_BIOS_VERSION"
    ;;
  system-uuid)

    [ -z "$TEST_SYSTEM_UUID" ] && return 0

    echo "$TEST_SYSTEM_UUID"
    ;;
  baseboard-serial-number)

    [ -z "$TEST_BASEBOARD_SERIAL_NUMBER" ] && return 0

    echo "$TEST_BASEBOARD_SERIAL_NUMBER"
    ;;
  esac

  return 0
}

################################################################################
# ifdtool
################################################################################
TEST_ME_OFFSET="${TEST_ME_OFFSET:-}"

ifdtool_check_blobs_in_binary_mock() {
  # Emulating ME offset value check, check check_blobs_in_binary func. for more
  # inf.:
  # last argument is file
  local file="${*: -1}"

  # if called on BIOS_UPDATE_FILE call original tool
  if [ "$file" = "$BIOS_UPDATE_FILE" ]; then
    ifdtool "$@"
    return
  fi
  echo "Flash Region 2 (Intel ME): $TEST_ME_OFFSET"

  return 0
}

################################################################################
# cbmem
################################################################################
TEST_ME_DISABLED="${TEST_ME_DISABLED:-true}"
TEST_ME_HAP_DISABLED="${TEST_ME_HAP_DISABLED:-}"

cbmem_common_mock() {
  # should fail if fw is not coreboot
  local _tool="$1"

  [ "$TEST_IS_COREBOOT" != "true" ] && return 1
  echo "${FUNCNAME[0]}: using ${_tool}..."
  return 0
}

cbmem_check_if_me_disabled_mock() {
  # Emulating ME state checked in Coreboot table, check check_if_me_disabled func.
  # for more inf.:
  [ "$TEST_IS_COREBOOT" != "true" ] && return 1

  if [ "$TEST_ME_HAP_DISABLED" = "true" ]; then
    echo "ME is HAP disabled"
  elif [ "$TEST_ME_DISABLED" = "true" ]; then
    echo "ME is disabled"
  fi

  return 0
}

################################################################################
# cbfstool
################################################################################
TEST_VBOOT_ENABLED="${TEST_VBOOT_ENABLED:-}"
TEST_ROMHOLE_MIGRATION="${TEST_ROMHOLE_MIGRATION:-}"
TEST_DIFFERENT_FMAP="${TEST_DIFFERENT_FMAP:-}"
TEST_FMAP_REGIONS="${TEST_FMAP_REGIONS:-}"
TEST_IS_SEABIOS="${TEST_IS_SEABIOS:-}"
TEST_IS_COREBOOT="${TEST_IS_COREBOOT:-}"
TEST_GBB_WP_RO_OVERLAP="${TEST_GBB_WP_RO_OVERLAP:-}"
TEST_BOARD_HAS_SMMSTORE="${TEST_BOARD_HAS_SMMSTORE:-true}"
TEST_ROMHOLE_MIGRATION_FROM="${TEST_ROMHOLE_MIGRATION_FROM:-}"
TEST_ROMHOLE_MIGRATION_TO="${TEST_ROMHOLE_MIGRATION_TO:-}"
TEST_READ_ROMHOLE_FAIL="${TEST_READ_ROMHOLE_FAIL:-false}"

check_if_coreboot() {
  # if we are checking current firmware, return value based on TEST_IS_COREBOOT
  # otherwise check with cbfstool
  local file="$1"

  if [ "$file" != "$BIOS_UPDATE_FILE" ]; then
    [ "$TEST_IS_COREBOOT" = "true" ] && return 0
    return 1
  fi
  cbfstool "$file" print &>/dev/null
}

cbfstool_common_mock() {
  local _file_to_check="$1"
  if [ -n "$1" ]; then
    check_if_coreboot "$_file_to_check"
  else
    return 1
  fi
}

cbfstool_layout_mock() {
  # Emulating some fields in Coreboot Files System layout table:
  local _file_to_check="$1"
  local _regions
  IFS=" " read -r -a _regions <<<"$TEST_FMAP_REGIONS"

  if ! check_if_coreboot "$_file_to_check"; then
    return 1
  fi
  _region_to_list=$(parse_for_arg_return_next "-r" "$@")

  if [ -z "$_region_to_list" ]; then
    echo "This image contains the following sections that can be accessed with this tool:"
    echo ""
    # Emulating ROMHOLE presence, check romhole_migration function for more inf.:
    if [[ "$TEST_ROMHOLE_MIGRATION_FROM" == "flashmap" && "$_file_to_check" != "$BIOS_UPDATE_FILE" ]]; then
      echo "'ROMHOLE' (test)"
    elif [[ "$TEST_ROMHOLE_MIGRATION_TO" == "flashmap" && "$_file_to_check" == "$BIOS_UPDATE_FILE" ]]; then
      echo "'ROMHOLE' (test)"
    fi

    # Emulating difference in Coreboot FS, check function
    # set_flashrom_update_params for more inf.:
    [ "$TEST_DIFFERENT_FMAP" = "true" ] && [ "$_file_to_check" != "$BIOS_DUMP_FILE" ] && echo "test"

    for region in "${_regions[@]}"; do
      if [[ "$region" = "GBB" && -z "$TEST_GBB_WP_RO_OVERLAP" ]]; then
        echo "'$region' (size 100, offset 1000)"
      else
        echo "'$region' (size 100, offset 100)"
      fi
    done
  elif [[ "$_region_to_list" == "COREBOOT" ]]; then
    echo "FMAP REGION: COREBOOT"
    echo "Name                           Offset     Type           Size   Comp"
    if [[ "$TEST_ROMHOLE_MIGRATION_FROM" == "cbfs" && "$_file_to_check" != "$BIOS_UPDATE_FILE" ]]; then
      echo "msi_romhole.bin"
    elif [[ "$TEST_ROMHOLE_MIGRATION_TO" == "cbfs" && "$_file_to_check" == "$BIOS_UPDATE_FILE" ]]; then
      echo "msi_romhole.bin"
    fi
  fi

  return 0
}

cbfstool_read_romhole_mock() {
  # Emulating reading ROMHOLE section from dumped firmware, check
  # romhole_migration func for more inf.:
  local _file_to_check="$1"
  local _file_to_write_into
  _file_to_write_into=$(parse_for_arg_return_next "-f" "$@")

  if ! check_if_coreboot "$_file_to_check"; then
    return 1
  fi

  [[ "$TEST_READ_ROMHOLE_FAIL" == "true" ]] && return 1

  echo "Testing..." >"$_file_to_write_into"

  return 0
}

cbfstool_read_bios_conffile_mock() {
  # Emulating reading bios configuration and some fields inside it.
  local _file_to_check="$1"
  local _file_to_write_into
  _file_to_write_into=$(parse_for_arg_return_next "-f" "$@")

  if ! check_if_coreboot "$_file_to_check"; then
    return 1
  fi

  cat /dev/null >"$_file_to_write_into"

  if [ "$TEST_VBOOT_ENABLED" = "true" ]; then
    # Emulating VBOOT presence, check firmware_pre_installation_routine and
    # firmware_pre_updating_routine funcs for more inf.:
    echo "CONFIG_VBOOT=y" >>"$_file_to_write_into"
  fi

  if [ "$TEST_IS_SEABIOS" = "true" ]; then
    # Emulating SeaBIOS payload presence, check function choose_version for more
    # inf..
    echo "CONFIG_PAYLOAD_SEABIOS=y" >>"$_file_to_write_into"
  fi

  echo "" >>"$_file_to_write_into"

  return 0
}

cbfstool_read_bootsplash_mock() {
  # Emulate extracting bootsplash from fw
  local _file_to_check="$1"
  local _file_to_write_into
  _file_to_write_into=$(parse_for_arg_return_next "-f" "$@")

  if ! check_if_coreboot "$_file_to_check"; then
    return 1
  fi

  if [ "$TEST_BOARD_HAS_BOOTSPLASH" = "true" ]; then
    echo "bootsplash" >"$_file_to_write_into"
  else
    return 1
  fi

  return 0
}

cbfstool_smmstore_mock() {
  # Emulate writing smmstore to file
  local _file_to_check="$1"
  local _file_to_write_into
  _file_to_write_into=$(parse_for_arg_return_next "-f" "$@")

  if ! check_if_coreboot "$_file_to_check"; then
    return 1
  fi

  if [ "$_file_to_check" = "$BIOS_UPDATE_FILE" ]; then
    # return result based on if update file has SMMSTORE region. It should fail
    # e.g. for novacustom heads binary
    cbfstool "$_file_to_check" layout | grep "SMMSTORE"
    return
  else
    if [ "$TEST_BOARD_HAS_SMMSTORE" = "true" ]; then
      return 0
    else
      return 1
    fi
  fi
}

################################################################################
# dmesg
################################################################################
TEST_TOUCHPAD_ENABLED=${TEST_TOUCHPAD_ENABLED:-}

dmesg_i2c_hid_detect_mock() {
  # Emulating touchpad presence and name detection, check touchpad-info script for
  # more inf.:
  if [ "$TEST_TOUCHPAD_ENABLED" = "true" ]; then
    echo "hid-multitouch: I2C HID Test"
  fi

  return 0
}

################################################################################
# futility
################################################################################
TEST_VBOOT_KEYS=${TEST_VBOOT_KEYS:-false}
TEST_DIFFERENT_VBOOT_KEYS=${TEST_DIFFERENT_VBOOT_KEYS:-}

futility_dump_vboot_keys_mock() {
  # Emulating VBOOT keys difference to trigger GBB region migration, check
  # check_vboot_keys func. for more inf.:
  local _file_to_check
  _file_to_check=$(parse_for_arg_return_next show "$@")
  if [ "${TEST_VBOOT_KEYS}" = "false" ]; then
    return 1
  fi

  if [ "$TEST_DIFFERENT_VBOOT_KEYS" = "true" ]; then
    [ "$_file_to_check" = "$BIOS_UPDATE_FILE" ] && echo "key sha1sum: Test1"
    [ "$_file_to_check" = "$BIOS_DUMP_FILE" ] && echo "key sha1sum: Test2"
  fi

  return 0
}
################################################################################
# fsread_tool
################################################################################
TEST_HCI_PRESENT="${TEST_HCI_PRESENT:-}"
TEST_TOUCHPAD_HID="${TEST_TOUCHPAD_HID:-}"
TEST_TOUCHPAD_PATH="${TEST_TOUCHPAD_PATH:-}"
TEST_AC_PRESENT="${TEST_AC_PRESENT:-}"
TEST_MEI_CONF_PRESENT="${TEST_MEI_CONF_PRESENT:-true}"
TEST_INTEL_IS_FUSED="${TEST_INTEL_IS_FUSED:-}"
TEST_SOUND_CARD_PRESENT="${TEST_SOUND_CARD_PRESENT:-true}"
TEST_EFI_PRESENT="${TEST_EFI_PRESENT:-true}"
TEST_FUM="${TEST_FUM:-false}"

fsread_tool_common_mock() {
  # This functionn emulates read hardware specific file system resources or its
  # metadata. It redirects flow into a tool-specific mocking function, which then
  # does needed work. e.g. fsread_tool_test_mock for test tool.
  local _tool="$1"
  shift

  fsread_tool_${_tool}_mock "$@"

  return $?
}

fsread_tool_test_mock() {
  local _arg_d
  local _arg_f
  local _arg_e
  _arg_d="$(parse_for_arg_return_next -d "$@")"
  _arg_f="$(parse_for_arg_return_next -f "$@")"
  _arg_e="$(parse_for_arg_return_next -e "$@")"

  if [ "$_arg_d" = "/sys/class/pci_bus/0000:00/device/0000:00:16.0" ]; then
    # Here we emulate the HCI hardware presence checked by function
    # check_if_heci_present in dts-hal.sh. Currently it is assumed the HCI is
    # assigned to a specific sysfs path (check the condition above):
    [ "$TEST_HCI_PRESENT" = "true" ] && return 0
  fi

  if [ "$_arg_f" = "/sys/class/mei/mei0/fw_status" ]; then
    # Here we emulate MEI controller status file presence, check check_if_fused
    # func for more inf.:
    [ "$TEST_MEI_CONF_PRESENT" = "true" ] && return 0
  fi

  if [ "$_arg_f" = "${FUM_EFIVAR}" ]; then
    # Emulate Firmware Update Mode (FUM)
    [ "$TEST_FUM" = "true" ] && return 0
  fi

  if [ "$_arg_e" = "/sys/class/power_supply/AC/online" ]; then
    # Emulating AC status file presence, check check_if_ac func. for more inf.:
    [ "$TEST_AC_PRESENT" = "true" ] && return 0
  fi

  if [ "$_arg_f" = "/sys/class/sound/card0/hw*/init_pin_configs" ] || [ "$_arg_f" = "/proc/asound/card0/codec#*" ]; then
    # Emulate sound card presence, check dasharo-hcl-report for more inf.:
    [ "$TEST_SOUND_CARD_PRESENT" = "true" ] && return 0
  fi

  if [ "$_arg_d" = "/sys/firmware/efi" ]; then
    # Emulate sysfs EFI presence:
    [ "$TEST_EFI_PRESENT" = "true" ] && return 0
  fi

  return 1
}

fsread_tool_cat_mock() {
  local _file_to_cat
  _file_to_cat="$1"

  # Note, Test folder here comes from dmesg_i2c_hid_detect_mock, which is being
  # called before fsread_tool_cat_mock in touchpad-info script:
  if [ "$_file_to_cat" = "/sys/bus/i2c/devices/Test/firmware_node/hid" ] && [ -n "$TEST_TOUCHPAD_HID" ]; then
    # Used in touchpad-info script.
    echo "$TEST_TOUCHPAD_HID"
  # Note, Test folder here comes from dmesg_i2c_hid_detect_mock, which is being
  # called before fsread_tool_cat_mock in touchpad-info script:
  elif [ "$_file_to_cat" = "/sys/bus/i2c/devices/Test/firmware_node/path" ] && [ -n "$TEST_TOUCHPAD_PATH" ]; then
    # Used in touchpad-info script.
    echo "$TEST_TOUCHPAD_PATH"
  elif [ "$_file_to_cat" = "/sys/class/power_supply/AC/online" ]; then
    # Emulating AC adadpter presence, used in check_if_ac func.:
    if [ "$TEST_AC_PRESENT" = "true" ]; then
      echo "1"
    else
      echo "0"
    fi
  elif [ "$_file_to_cat" = "/sys/class/mei/mei0/fw_status" ] && [ "$TEST_MEI_CONF_PRESENT" = "true" ]; then
    # Emulating MEI firmware status file, for more inf., check check_if_fused
    # func.:
    echo "smth"
    echo "smth"
    echo "smth"
    echo "smth"
    echo "smth"
    # Emulating Intel Secure Boot Fuse status, check check_if_fused func. for
    # more inf. 4... if fused, and 0 if not:
    if [ "${TEST_INTEL_IS_FUSED}" = "true" ]; then
      echo "40000000"
    else
      echo "00000000"
    fi
    echo "smth"
  else
    echo "${FUNCNAME[0]}: ${_file_to_cat}: No such file or directory"

    return 1
  fi

  return 0
}

################################################################################
# setpci
################################################################################
TEST_ME_OP_MODE="${TEST_ME_OP_MODE:-0}"

setpci_check_me_op_mode_mock() {
  # Emulating current ME operation mode, check functions check_if_me_disabled and
  # check_me_op_mode:
  echo "0$TEST_ME_OP_MODE"

  return 0
}

################################################################################
# lscpu
################################################################################
lscpu_common_mock() {
  # Emulating lscpu's "Model name" CPU model listing, check update_workflow
  # function. The CPU version should look like:
  # "13th Gen Intel(R) Core(TM) i9-13900K":
  echo "  Model name:                $TEST_CPU_VERSION"

  return 0
}

################################################################################
# msrtool
################################################################################
TEST_MSRTOOL="${TEST_MSRTOOL:-}"

msrtool_common_mock() {
  # print random msr if TEST_MSRTOOL is true otherwise print error
  if [ "$TEST_MSRTOOL" = "true" ]; then
    echo "# MSR_THERM2_CTL"
    echo "0x0000019d"
    return 0
  else
    echo "can not decode any MSRs!" >&2
    return 1
  fi
}

################################################################################
# rdmsr
################################################################################
TEST_MSR_CAN_BE_READ="${TEST_MSR_CAN_BE_READ:-true}"
TEST_FPF_PROGRAMMED="${TEST_FPF_PROGRAMMED:-0}"
TEST_VERIFIED_BOOT_ENABLED="${TEST_VERIFIED_BOOT_ENABLED:-0}"

rdmsr_boot_guard_status_mock() {
  local _bits_8_5="0"
  # Emulating MSR accessibility, for more inf. check
  # check_if_boot_guard_enabled func.:
  [ "$TEST_MSR_CAN_BE_READ" != "true" ] && return 1

  # Emulating Boot Guard status. 0000000000000000 - FPF not fused and Verified
  # Boot disabled, 0000000000000010 - FPF fused and Verified Boot disabled,
  # 0000000000000020 - FPF not fused and Verified Boot enabled, 0000000000000030
  # - FPF fused and Verified Boot enabled. For more inf. check
  # check_if_boot_guard_enabled func.:
  _bits_8_5=$((${_bits_8_5} + ${TEST_FPF_PROGRAMMED} + ${TEST_VERIFIED_BOOT_ENABLED}))

  echo "00000000000000${_bits_8_5}0"

  return 0
}

################################################################################
# mei-amt-check
################################################################################
TEST_MEI_AMT_CHECK="${TEST_MEI_AMT_CHECK:-}"

mei-amt-check_common_mock() {
  if [ "$TEST_MEI_AMT_CHECK" = "true" ]; then
    return 0
  else
    return 1
  fi
}

################################################################################
# amdtool
################################################################################

amdtool_on_amd_mock() {
  # lowercase
  local cpu="${TEST_CPU_VERSION,,}"

  if [[ "$cpu" == *amd* ||
    "$cpu" == *"advanced micro devices"* ]]; then
    return 0
  fi
  return 1
}

################################################################################
# cap_upd_tool
################################################################################

cap_upd_tool_common_mock() {
  return 0
}

################################################################################
# cap_upd_tool
################################################################################
# Set this variable to:
# - leave empty - call original tool
# - "success" - key verification succeeded
# - "fail_hash" - key verification failed with hash error
# - anything else - return 1 and don't print anything
TEST_KEY_VALIDATOR_RESULT="${TEST_KEY_VALIDATOR_RESULT:-}"

btg_key_validator_common_mock() {
  if [ -z "${TEST_KEY_VALIDATOR_RESULT}" ]; then
    btg_key_validator "$@"
    return
  elif [ "${TEST_KEY_VALIDATOR_RESULT}" = "success" ]; then
    echo "Firmware is signed with expected key hash"
    return 0
  elif [ "${TEST_KEY_VALIDATOR_RESULT}" = "fail_hash" ]; then
    print_error "Firmware signature doesn't match expected hash"
  fi
  return 1
}
