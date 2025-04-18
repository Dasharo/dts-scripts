#!/bin/bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

SBIN_DIR="/usr/sbin"
FUM_EFIVAR="/sys/firmware/efi/efivars/FirmwareUpdateMode-d15b327e-ff2d-4fc1-abf6-c12bd08c1359"

export DTS_FUNCS="$SBIN_DIR/dts-functions.sh"
export DTS_ENV="$SBIN_DIR/dts-environment.sh"
export DTS_SUBS="$SBIN_DIR/dts-subscription.sh"
export DTS_HAL="$SBIN_DIR/dts-hal.sh"
export DTS_MOCK_COMMON="$SBIN_DIR/common-mock-func.sh"
export BASH_ENV="$SBIN_DIR/logging"
export TMP_LOG_DIR="/tmp/logs"
export ERR_LOG_FILE_REALPATH
export DTS_LOG_FILE
export DTS_VERBOSE_LOG_FILE
export ERR_LOG_FILE
export SHELLOPTS

mkdir -p "$TMP_LOG_DIR"
# $ERR_LOG_FILE is fd that can only be written to: '>()'. To copy logs
# we need underlying file that can be copied
ERR_LOG_FILE_REALPATH="/var/local/dts-err_$(basename "$(tty)").log"
DTS_LOG_FILE="$TMP_LOG_DIR/dts_$(basename "$(tty)").log"
DTS_VERBOSE_LOG_FILE="$TMP_LOG_DIR/dts-verbose_$(basename "$(tty)").log"

# shellcheck source=./logging
source "$BASH_ENV"
start_trace_logging
start_logging
if [ -z "$ERR_LOG_FILE" ]; then
  # pass everything written to $ERR_LOG_FILE to logger function and save it's
  # output to $ERR_LOG_FILE_REALPATH file
  exec {ERR_LOG_FILE}> >(logger >>"$ERR_LOG_FILE_REALPATH")
  ERR_LOG_FILE="/proc/$$/fd/$ERR_LOG_FILE"
fi

# shellcheck source=../include/dts-environment.sh
source $DTS_ENV
# shellcheck source=../include/dts-functions.sh
source $DTS_FUNCS
# shellcheck source=../include/hal/dts-hal.sh
source $DTS_HAL

if [ -f $FUM_EFIVAR ]; then
  $SBIN_DIR/dasharo-deploy update fum
else
  $SBIN_DIR/dts
fi
