# shellcheck source=../include/dts-environment.sh
source $DTS_ENV

parse_for_arg_return_next(){ # TODO place in dts-functions.sh
# This function parses a list of arguments (given as a second argument), looks
# for a specified argument (given as a first argument). In case the specified
# argument has been found in the list - this function returns (to stdout) the
# argument, wich is on the list after specified one, and a return value 0,
# otherwise nothing is being printed to stdout and the return value is 1.
# Arguments:
# 1. The argument you are searching for like -r for flashrom;
# 2. Space-separated list of arguments to search in.
  local _arg="$1"
  shift

  while [[ $# -gt 0 ]]; do
    if [ "$1" = "$_arg" ]; then
      [ -n "$2" ] && echo "$2" 1>&1

      return 0
    else
      shift
    fi
  done

  return 1
}

################################################################################
# flashrom
################################################################################
TEST_FLASH_LOCK="${TEST_FLASH_LOCK:-true}"
TEST_AUTO_FLASH_CHIP_DETECT="${TEST_AUTO_FLASH_CHIP_DETECT:-true}"
TEST_BOARD_HAS_FD_REGION="${TEST_BOARD_HAS_FD_REGION:-true}"
TEST_BOARD_FD_REGION_RW="${TEST_BOARD_FD_REGION_RW:-true}"
TEST_BOARD_HAS_ME_REGION="${TEST_BOARD_HAS_ME_REGION:-true}"
TEST_BOARD_ME_REGION_RW="${TEST_BOARD_ME_REGION_RW:-true}"
TEST_BOARD_ME_REGION_LOCKED="${TEST_BOARD_ME_REGION_LOCKED:-}"
TEST_BOARD_HAS_GBE_REGION="${TEST_BOARD_HAS_GBE_REGION:-true}"
TEST_BOARD_GBE_REGION_RW="${TEST_BOARD_GBE_REGION_RW:-true}"
TEST_BOARD_GBE_REGION_LOCKED="${TEST_BOARD_GBE_REGION_LOCKED:-}"
TEST_COMPATIBLE_EC_VERSINO="${TEST_COMPATIBLE_EC_VERSINO:-}"

flashrom_common_mock(){
  echo "${FUNCNAME[0]}: Using flashrom..."

  return 0
}

flashrom_check_flash_lock_mock(){
# For flash lock testing:
  if [ -n "$TEST_FLASH_LOCK" ]; then
    echo "PR0: Warning:.TEST is read-only\|SMM protection is enabled" > /tmp/check_flash_lock.err
    return 1
  fi

  return 0
}

flashrom_flash_chip_name_mock(){
  if [ -n "$TEST_AUTO_FLASH_CHIP_DETECT" ]; then
    echo "Test Flash Chip" 1>&1

    return 0
  else
    # TODO
    return 1
  fi

}

flashrom_flash_chip_size_mock(){
  echo "Test Size of The Flash Chip " 1>&1

  return 0
}

flashrom_check_intel_regions_mock(){
  [ -n "$TEST_BOARD_HAS_FD_REGION" ] && echo "Flash Descriptor region" 1>&1
  [ -n "$TEST_BOARD_FD_REGION_RW" ] && echo "Flash Descriptor region.testread-write" 1>&1

  [ -n "$TEST_BOARD_HAS_ME_REGION" ] && echo "Management Engine region" 1>&1
  [ -n "$TEST_BOARD_ME_REGION_RW"] && echo "Management Engine region.testread-write" 1>&1 
  [ -n "$TEST_BOARD_ME_REGION_LOCKED" ] && echo "Management Engine region.testlocked" 1>&1

  [ -n "$TEST_BOARD_HAS_GBE_REGION" ] && echo "Gigabit Ethernet region" 1>&1
  [ -n "$TEST_BOARD_GBE_REGION_RW" ] && echo "Gigabit Ethernet region.testread-write" 1>&1
  [ -n "$TEST_BOARD_GBE_REGION_LOCKED" ] && echo "Gigabit Ethernet region.testlocked" 1>&1

  return 0
}

flashrom_read_flash_layout_mock(){
  # For -r check flashrom man page:
  local _file_to_write_into=$(parse_for_arg_return_next "-r" $*)
  echo "Testing..." > "$_file_to_write_into"
  
  return 0
}

flashrom_read_firm_mock(){
  # For -r check flashrom man page:
  local _file_to_write_into=$(parse_for_arg_return_next "-r" $*)

  echo "Test flashrom read." > "$_file_to_write_into"

  return 0
}

flashrom_get_ec_firm_version_mock(){
  if [ -n "$TEST_COMPATIBLE_EC_VERSION" ]; then
    echo "Mainboard EC Version: $COMPATIBLE_EC_FW_VERSION" 1>&1
  else
    echo "Mainboard EC Version: 0000-00-00-0000000"
  fi

  return 0
}

flashrom_write_firm_mock(){
  echo "${FUNCNAME[0]}: Writing firmware..."
  return 0
}

################################################################################
# ectool
################################################################################
ectool_common_mock(){
  echo "${FUNCNAME[0]}: Usinng ectool..."

  return 0
}

################################################################################
# dasharo_ectool
################################################################################
dasharo_ectool_common_mock(){
  # TODO
}

dasharo_ectool_check_for_opensource_firm_mock(){
  # TODO
}

dasharo_ectool_update_ec_firmware_mock(){
  # TODO
}

novacustom_check_sys_model_mock(){
  # TODO
}

################################################################################
# dmidecode
################################################################################
dmidecode_common_mock(){
  # TODO
}

################################################################################
# ifdtool
################################################################################
ifdtool_common_mock(){
  # TODO
}

ifdtool_check_blobs_in_binary_mock(){
  # TODO
}

################################################################################
# cbmem
################################################################################
cbmem_common_mock(){
  # TODO
}

cbmem_check_if_me_disabled_mock(){
  # TODO
}

################################################################################
# cbfstool
################################################################################
cbfstool_common_mock(){
  # TODO
}

cbfstool_layout_mock(){
  # TODO
}

cbfstool_read_romhole_mock(){
  # TODO
}

cbfstool_read_logo_mock(){
  # TODO
}

cbfstool_read_bios_conffile_mock(){
  # TODO
}

################################################################################
# superiotool
################################################################################
superiotool_common_mock(){
  # TODO
}

################################################################################
# msrtool
################################################################################
msrtool_common_mock(){
  # TODO
}

################################################################################
# biosdecode
################################################################################
biosdecode_common_mock(){
  # TODO
}

################################################################################
# nvramtool
################################################################################
nvramtool_common_mock(){
  # TODO
}

################################################################################
# inteltool
################################################################################
inteltool_common_mock(){
  # TODO
}

################################################################################
# intelp2m
################################################################################
intelp2m_common_mock(){
  # TODO
}

################################################################################
# decode-dimms
################################################################################
decode-dimms_common_mock(){
  # TODO
}

################################################################################
# mei-amt-check
################################################################################
mei-amt-check_common_mock(){
  # TODO
}

################################################################################
# intelmetool
################################################################################
intelmetool_common_mock(){
  # TODO
}

################################################################################
# hw-probe
################################################################################
hw-probe_common_mock(){
  # TODO
}

################################################################################
# dmesg
################################################################################
dmesg_common_mock(){
  # TODO
}

dmesg_i2c_hid_detect_mock(){
  # TODO
}

################################################################################
# dcu
################################################################################
dcu_common_mock(){
  # TODO
}

################################################################################
# futility
################################################################################
futility_common_mock(){
  # TODO
}

################################################################################
# iotools
################################################################################
iotools_common_mock(){
  # TODO
}

################################################################################
# fsread_tool
################################################################################
fsread_tool_common_mock(){
  # TODO
}

fsread_tool_check_if_ac_mock(){
  # TODO
}

################################################################################
# setpci
################################################################################
setpci_common_mock(){
  # TODO
}

setpci_set_me_opmode_bits_mock(){
  # TODO
}

################################################################################
# cap_upd_tool
################################################################################
cap_upd_tool_common_mock(){
  # TODO
}

################################################################################
# lscpu
################################################################################
lscpu_common_mock(){
  # TODO
}

################################################################################
# i2cdetect
################################################################################
i2cdetect_common_mock(){
  # TODO
}

################################################################################
# reboot
################################################################################
reboot_common_mock(){
  # TODO
}

################################################################################
# poweroff
################################################################################
poweroff_common_mock(){
  # TODO
}
