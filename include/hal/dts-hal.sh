#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0
#
# This is a Hardware Abstraction Layer for DTS. The goal of this layer -
# separate all hardware-related code from DTS code to improve readability,
# scalability and testing.
#
# For testing, every non hardware-specific function must utilize DTS_TESTING
# variable, which is declared in dts-environment and set by user. If DTS_TESTING
# is not "true" - HAL communicates with hardware and firmware, otherwise every
# HAL function should return non real, testing values. The structure of the
# functions should  be following:
#
# FUNCTION_NAME(){
# # FUNCTION_DESCRIBTION
#
#   if [ "$DTS_TESTING" = "true" ]; then
#     TEST_RELATED_RETURNS
#   fi
#
#   HARDWARE_OR_FIRMWARE_STUFF
#
# }

# shellcheck disable=SC2034

# shellcheck source=./dts-hal-common.sh
source $DTS_ENV
# shellcheck source=./dts-hal-common.sh
source $DTS_MOCK_COMMON

# Set tools wrappers:
DASHARO_ECTOOL="tool_wrapper dasharo_ectool"
FLASHROM="tool_wrapper flashrom"
DMIDECODE="tool_wrapper dmidecode"
IFDTOOL="tool_wrapper ifdtool"
SETPCI="tool_wrapper setpci"
CBMEM="tool_wrapper cbmem"
CBFSTOOL="tool_wrapper cbfstool"
SUPERIOTOOL="tool_wrapper superiotool"
ECTOOL="tool_wrapper ectool"
MSRTOOL="tool_wrapper msrtool"
BIOSDECODE="tool_wrapper biosdecode"
NVRAMTOOL="tool_wrapper nvramtool"
INTELTOOL="tool_wrapper inteltool"
INTELP2M="tool_wrapper intelp2m"
DECODE_DIMS="tool_wrapper decode-dimms"
MEI_AMT_CHECK="tool_wrapper mei-amt-check"
INTELMETOOL="tool_wrapper intelmetool"
HW_PROBE="tool_wrapper hw-probe"
DMESG="tool_wrapper dmesg"
DCU="tool_wrapper dcu"
FUTILITY="tool_wrapper futility"
IOTOOLS="tool_wrapper iotools"
FSREAD_TOOL="tool_wrapper fsread_tool"
CAP_UPD_TOOL="tool_wrapper cap_upd_tool"
LSCPU="tool_wrapper lscpu"
I2CDETECT="tool_wrapper i2cdetect"
# System commands:
POWEROFF="tool_wrapper poweroff"
REBOOT="tool_wrapper reboot"

################################################################################
# Tools wrapper.
################################################################################
tool_wrapper(){
  local _input
  read -r -d '' _input
  local _tool="$1"
  local _mock_func="$2"
  if ! echo "$_mock_func" | grep "_mock"; then
    unset _mock_func
    shift 1
  else
    shift 2
  fi
  local _arguments="$*"

  if [ "$DTS_TESTING" = "true" ]; then
    if [ -z "$_mock_func" ]; then
      echo "$_input" | ${_tool}_common_mock $_arguments 1>&1 2>&2
    else

      if type $_mock_func &> /dev/null; then
        echo "$_input" | $_mock_func $_arguments 1>&1 2>&2
      elif type ${_tool}_$_mock_func &> /dev/null; then
	echo "$_input" | ${_tool}_$_mock_func $_arguments 1>&1 2>&2
      else
	echo "$_input" | ${_tool}_common_mock $_arguments 1>&1 2>&2
      fi
    fi

    return $?
  fi

  echo "$_input" | $_tool $_arguments 1>&1 2>&2

  return $?
}

################################################################################
# Other funcs.
################################################################################
check_for_opensource_firmware()
{
  echo "Checking for Open Source Embedded Controller firmware..."
  $DASHARO_ECTOOL check_for_opensource_firm_mock info >> /dev/null 2>&1

  return $?
}

fsread_tool(){
# This func is an abstraction for proper handling of fs hardware-specific (e.g.
# checking devtmpfs, or sysfs, or some other fs that changes its state due to
# changes in hardware and/or firmware) reads by tool_wrapper.
#
# This function does not have arguments in common understanding, it takes a
# command, that is reading smth from some fs, and its arguments as an only
# argument. E.g. if you want to check tty1 device presence:
#
# fsread_tool test -f /dev/tty1
  local _command="$*"

  $_command

  return $?
}

cap_upd_tool(){
# This func is an abstraction for proper handling of UEFI Capsule Update driver
# writing by the tool_wrapper. arguments: capsule update file path, e.g.:
#
# capsule_update_tool /tmp/firm.cap
  local _capsule="$1"

  cat "$_capsule" > "$CAP_UPD_DEVICE"

  return $?
}

check_if_heci_present(){
  # FIXME: what if HECI is not device 16.0?
  $FSREAD_TOOL test -d /sys/class/pci_bus/0000:00/device/0000:00:16.0

  return $?
}

check_me_op_mode(){
# Checks ME Current Operation Mode at offset 0x40 bits 19:16:
  local _mode

  _mode="$($SETPCI set_me_opmode_bits_mock -s 00:16.0 42.B 2> /dev/null | cut -c2-)"

  echo "$_mode" 1>&1

  return 0
}
