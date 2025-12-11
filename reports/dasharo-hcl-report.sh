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

# Vars for controlling progress bar
progress_bar_cntr=0
PROGRESS_BAR_TASKS_TOTAL=30

# Helper vars
FW_DUMP_DEFAULT_PATH="logs/rom.bin"
fw_bin_path="$FW_DUMP_DEFAULT_PATH"

progress_bar_update() {
  local BAR_WIDTH=67

  # Increment counter
  ((progress_bar_cntr++))

  # Clamp counter
  if ((progress_bar_cntr > PROGRESS_BAR_TASKS_TOTAL)); then
    progress_bar_cntr=$PROGRESS_BAR_TASKS_TOTAL
  fi

  # Calculate progress
  local filled=$((progress_bar_cntr * BAR_WIDTH / PROGRESS_BAR_TASKS_TOTAL))
  local empty=$((BAR_WIDTH - filled))

  # Build bar
  local bar
  bar=$(printf "%0.s#" $(seq 1 $filled))
  if ((empty > 0)); then
    bar+=$(printf "%0.s " $(seq 1 $empty))
  fi

  # Print with carriage return
  printf "\r[%s] %d/%d" "$bar" "$progress_bar_cntr" "$PROGRESS_BAR_TASKS_TOTAL"
}

update_result() {
  TOOL=$1
  ERRORFILE=$2
  LOGFILE=$(printf $2 | sed 's/[.].*$//' && echo ".log")

  # check if status was set as a unknown
  if [[ "$3" == "UNKNOWN" ]]; then
    echo -e [$YELLOW"UNKNOWN"$NORMAL]"\t"$TOOL >>result
    return
  fi

  ERR=$(stat -c%s "$ERRORFILE" 2>/dev/null)
  LOG=$(stat -c%s "$LOGFILE" 2>/dev/null)

  # if ERR or LOG var is empty, set it to 1 so we will go into UNKNOWN state
  if [ -z "$LOG" ]; then
    LOG=1
  fi
  if [ -z "$ERR" ]; then
    ERR=1
  fi
  # specific check for firmware dump
  if [ $LOGFILE == "logs/flashrom_read.log" ]; then
    if [ $LOG -ne 0 ] && [ -f "$FW_DUMP_DEFAULT_PATH" ]; then
      echo -e [$GREEN"OK"$NORMAL]"\t\t"$TOOL >>result
    else
      echo -e [$RED"ERROR"$NORMAL]"\t\t"$TOOL >>result
    fi
    return
  fi

  # generic checks
  if [ $LOG -ne 0 ] && [ $ERR -eq 0 ]; then
    echo -e [$GREEN"OK"$NORMAL]"\t\t"$TOOL >>result
  elif [ $LOG -eq 0 ] && [ $ERR -ne 0 ]; then
    echo -e [$RED"ERROR"$NORMAL]"\t\t"$TOOL >>result
  else
    echo -e [$YELLOW"UNKNOWN"$NORMAL]"\t"$TOOL >>result
  fi
}

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be started as root!"
  exit 1
fi

if [ -d logs ]; then
  rm -rf logs
fi

mkdir logs
if [ $DEPLOY_REPORT = "false" ]; then
  echo "Getting hardware information. It will take a few minutes..."
fi
# echo "Dumping PCI configuration space and topology..."
$LSPCI -nnvvvxxxx >logs/lspci.log 2>logs/lspci.err.log
update_result "PCI configuration space and topology" logs/lspci.err.log
progress_bar_update

# echo "Dumping USB devices and topology..."
$LSUSB -vvv >logs/lsusb.log 2>logs/lsusb.err.log
update_result "USB devices and topology" logs/lsusb.err.log
progress_bar_update

# echo "Dumping Super I/O configuration..."
$SUPERIOTOOL -deV >logs/superiotool.log 2>logs/superiotool.err.log
update_result "Super I/O configuration" logs/superiotool.err.log
progress_bar_update

# echo "Dumping Embedded Controller configuration (this may take a while if EC is not present)..."
$ECTOOL -ip >logs/ectool.log 2>logs/ectool.err.log
update_result "EC configuration" logs/ectool.err.log
progress_bar_update

# echo "Dumping MSRs..."
$MSRTOOL >logs/msrtool.log 2>logs/msrtool.err.log
update_result "MSRs" logs/msrtool.err.log
progress_bar_update

# echo "Dumping SMBIOS tables..."
$DMIDECODE >logs/dmidecode.log 2>logs/dmidecode.err.log
update_result "SMBIOS tables" logs/dmidecode.err.log
progress_bar_update

# echo "Decoding BIOS information..."
biosdecode >logs/biosdecode.log 2>logs/biosdecode.err.log
update_result "BIOS information" logs/biosdecode.err.log
progress_bar_update

# echo "Extracting CMOS NVRAM..."
nvramtool -x >logs/nvramtool.log 2>logs/nvramtool.err.log
update_result "CMOS NVRAM" logs/nvramtool.err.log
progress_bar_update

# echo "Dumping Intel configuration registers..."
inteltool -a >logs/inteltool.log 2>logs/inteltool.err.log
update_result "Intel configuration registers" logs/inteltool.err.log
progress_bar_update

# echo "Dumping AMD configuration registers..."
$AMDTOOL on_amd_mock -a >logs/amdtool.log 2>logs/amdtool.err.log
update_result "AMD configuration registers" logs/amdtool.err.log
progress_bar_update

# echo "Generating GPIO configuration C header files for coreboot..."
intelp2m -file logs/inteltool.log -fld cb -i -p snr -o logs/gpio_snr.h >logs/intelp2m.log 2>logs/intelp2m.err.log
intelp2m -file logs/inteltool.log -fld cb -i -p cnl -o logs/gpio_cnl.h >>logs/intelp2m.log 2>>logs/intelp2m.err.log
intelp2m -file logs/inteltool.log -fld cb -i -p apl -o logs/gpio_apl.h >>logs/intelp2m.log 2>>logs/intelp2m.err.log
intelp2m -file logs/inteltool.log -fld cb -i -p lbg -o logs/gpio_lbg.h >>logs/intelp2m.log 2>>logs/intelp2m.err.log
update_result "GPIO configuration C header files" logs/intelp2m.err.log
progress_bar_update

# echo "Dumping kernel dmesg..."
$DMESG >logs/dmesg.log 2>logs/dmesg.err.log
update_result "kernel dmesg" logs/dmesg.err.log
progress_bar_update

# echo "Dumping ACPI tables..."
acpidump >logs/acpidump.log 2>logs/acpidump.err.log
update_result "ACPI tables" logs/acpidump.err.log
progress_bar_update

# echo "Dumping Audio devices configuration..."
# FIXME: https://github.com/Dasharo/dts-scripts/issues/108

# This is a workaround to soundcard's files absence in short time after booting.
# Thread is continued here https://github.com/Dasharo/dasharo-issues/issues/247
for t in {1..12}; do
  SND_HW_FILES="/sys/class/sound/card0/hw*/init_pin_configs"
  SND_CODEC_FILES="/proc/asound/card0/codec#*"
  SND_HW_FILE=$(echo $SND_HW_FILES | cut -d ' ' -f 1)
  SND_CODEC_FILE=$(echo $SND_CODEC_FILES | cut -d ' ' -f 1)

  if $FSREAD_TOOL test -f "$SND_HW_FILE" && $FSREAD_TOOL test -f "$SND_CODEC_FILE"; then
    break
  else
    sleep 5
    if [ $t -eq 12 ]; then
      if [ $DEPLOY_REPORT = "false" ]; then
        clear_line
        print_warning 'Sound card files are missing!'
      fi
    fi
  fi
done

for x in /sys/class/sound/card0/hw*; do cat "$x/init_pin_configs" >logs/pin_"$(basename "$x")" 2>logs/pin_"$(basename "$x")".err.log; done
for x in /proc/asound/card0/codec#*; do cat "$x" >logs/"$(basename "$x")" 2>logs/"$(basename "$x")".err.log; done
update_result "Audio devices configuration" 0 UNKNOWN
progress_bar_update

# echo "Dumping CPU info..."
cat /proc/cpuinfo >logs/cpuinfo.log 2>logs/cpuinfo.err.log
update_result "CPU info" logs/cpuinfo.err.log
progress_bar_update

# echo "Dumping I/O ports..."
cat /proc/ioports >logs/ioports.log 2>logs/ioports.err.log
update_result "I/O ports" logs/ioports.err.log
progress_bar_update

# echo "Dumping input bus types..."
cat /sys/class/input/input*/id/bustype >logs/input_bustypes.log
update_result "Input bus types" logs/ioports.err.log
progress_bar_update

# flashrom does not support QEMU. TODO: this could be handled in a better way:
if [ "${SYSTEM_VENDOR}" != "QEMU" ] && [ "${SYSTEM_VENDOR}" != "Emulation" ]; then
  check_flash_chip >>/dev/null
  check_intel_regions

  # echo "Trying to read firmware image with flashrom..."
  # Some regions may be not available so we need to use specific regions to read
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

  $FLASHROM -V -p internal:laptop=force_I_want_a_brick ${FLASH_CHIP_SELECT} -r "${FW_DUMP_DEFAULT_PATH}" ${FLASHROM_ADD_OPT_READ} >logs/flashrom_read.log 2>logs/flashrom_read.err.log
  if [ $? -ne 0 ]; then
    clear_line
    print_error 'CRITICAL ERROR: cannot dump firmware!'
  fi
  update_result "Firmware image" logs/flashrom_read.err.log
fi
## Update progress bar anyway
progress_bar_update

# Run psptool on dumped or external firmware
if [ ! -f "$fw_bin_path" ] && [ -d "/firmware/external" ]; then
  count=$(ls -1A /firmware/external | wc -l)

  if [ "$count" -eq 1 ]; then
    clear_line
    print_warning "Firmware dump not found, but found user-supplied external binary."
    fw_bin_path="/firmware/external/$(ls -1A /firmware/external)"
  elif [ "$count" -gt 1 ]; then
    clear_line
    print_error "Multiple files found in /firmware/external! Make sure only a single file is present!"
  fi
fi
psptool -E "$fw_bin_path" >>logs/psptool.log 2>>logs/psptool.err.log
# FIXME: The following will always result in UNKNOWN
# There are two reasons for this:
# * The tool always returns 0, even if binary is for intel or just all zeros.
# * The warnings are redirected to stderr, running on "bad" binaries will just
#   print warnings, not errors.
# This needs to be fixed at tool level.
update_result "PSP firmware entries" logs/psptool.err.log
progress_bar_update

# echo "Probing all I2C buses..."
MAX_I2C_ID=$(i2cdetect -l | awk 'BEGIN{c1=0} //{c1++} END{print "",--c1}')
for bus in $(seq 0 "$MAX_I2C_ID"); do
  echo "I2C bus number: $bus" >>logs/i2cdetect.log 2>>logs/i2cdetect.err.log
  i2cdetect -y "$bus" >>logs/i2cdetect.log 2>>logs/i2cdetect.err.log
done
update_result "I2C bus" logs/i2cdetect.err.log
progress_bar_update

# echo "Decompiling ACPI tables..."
# FIXME: https://github.com/Dasharo/dts-scripts/issues/109
mkdir -p logs/acpi
if pushd logs/acpi >/dev/null 2>>"$ERR_LOG_FILE"; then
  acpixtract -a ../acpidump.log >/dev/null 2>>"$ERR_LOG_FILE"
  iasl -d ./*.dat >/dev/null 2>>"$ERR_LOG_FILE"
  popd >/dev/null 2>>"$ERR_LOG_FILE" || return 1
fi
update_result "ACPI tables" 0 UNKNOWN
progress_bar_update

# echo "Getting touchpad information..."
touchpad-info >logs/touchpad.log 2>logs/touchpad.err.log
update_result "Touchpad information" logs/touchpad.err.log
progress_bar_update

# echo "Getting DIMMs information..."
decode-dimms >logs/decode-dimms.log 2>logs/decode-dimms.err.log
update_result "DIMMs information" logs/decode-dimms.err.log
progress_bar_update

# echo "Getting CBMEM table..."
$CBMEM >logs/cbmem.log 2>logs/cbmem.err.log
update_result "CBMEM table information" logs/cbmem.err.log
progress_bar_update

# echo "Getting CBMEM console..."
$CBMEM -1 >logs/cbmem_console.log 2>logs/cbmem_console.err.log
update_result "CBMEM console" logs/cbmem_console.err.log
progress_bar_update

# echo "Getting TPM information..."
find "$(realpath /sys/class/tpm/tpm*)" -type f -print -exec cat {} \; >logs/tpm_version.log 2>logs/tpm_version.err.log
update_result "TPM information" logs/tpm_version.err.log
progress_bar_update

# dump all PCRs
rm -f "logs/tpm_pcrs.log" "logs/tpm_pcrs.err.log"
$DUMP_PCRS >>"logs/tpm_pcrs.log" 2>>"logs/tpm_pcrs.err.log"
update_result "TPM PCRs" logs/tpm_pcrs.err.log
progress_bar_update

# echo "Checking AMT..."
$MEI_AMT_CHECK >logs/amt-check.log 2>logs/amt-check.err.log
update_result "AMT information" logs/amt-check.err.log
progress_bar_update

# echo "Checking ME..."
$INTELMETOOL -m >logs/intelmetool.log 2>logs/intelmetool.err.log
update_result "ME information" logs/intelmetool.err.log
progress_bar_update

# echo "Getting graphics VBT"
# FIXME: https://github.com/Dasharo/dts-scripts/issues/110
files=$(find /sys/kernel/debug/dri -maxdepth 2 -name "i915_vbt")
for file in $files; do
  # copy $file to logs/dri_<directory>_<filename>
  cp "$file" "logs/dri_$(basename "$(dirname "$file")")_$(basename "$file")"
done
update_result "Graphics VBT" 0 UNKNOWN
progress_bar_update
# next two echo cmds helps with printing
echo
echo

echo "Results of getting data:" >>result
echo -e "\nLegend:" >>result
echo -e [$GREEN"OK"$NORMAL]"\t\t Data get successfully" >>result
echo -e [$YELLOW"UNKNOWN"$NORMAL]"\t Result is unknown" >>result
echo -e [$RED"ERROR"$NORMAL]"\t\t Error during getting data\n" >>result

mv result logs/result
if [ $DEPLOY_REPORT = "false" ]; then
  cat logs/result
fi

# Create name for generated report
filename="$($DMIDECODE dump_var_mock -s system-manufacturer)"
filename+=" $($DMIDECODE dump_var_mock -s system-product-name)"
filename+=" $($DMIDECODE dump_var_mock -s bios-version)"

# MAC address of device that is used to connect the internet
# it could return none only when there is no internet connection but
# in those cases report will be stored locally only.
# Ignore "SC2046 (warning): Quote this to prevent word splitting" shellcheck
# warning:
# shellcheck disable=SC2046
uuid_string="$(cat /sys/class/net/$(ip route show default | head -1 | awk '/default/ {print $5}')/address)"
# next two values are hardware related so they will be always the same
uuid_string+="_$($DMIDECODE dump_var_mock -s system-product-name)"
uuid_string+="_$($DMIDECODE dump_var_mock -s system-manufacturer)"

# using values from above should generate the same uuid all the time if only
# the MAC address will not change.
uuid=$(uuidgen -n @x500 -N $uuid_string -s)

filename+="_$uuid"
filename+="_$(date +'%Y_%m_%d_%H_%M_%S_%N')"
filename="${filename// /_}"
filename="${filename//\//_}"

if [ $DEPLOY_REPORT = "false" ]; then
  echo "Creating archive with logs..."
fi

# Remove MAC address from logs as sensitive data.
# Ignore "SC2046 (warning): Quote this to prevent word splitting" shellcheck
# warning:
# shellcheck disable=SC2046
MAC_ADDR=$(cat /sys/class/net/$(ip route show default | head -1 | awk '/default/ {print $5}')/address)
grep -rl "${MAC_ADDR}" logs >/dev/null && grep -rl "${MAC_ADDR}" logs | xargs sed -i 's/'${MAC_ADDR}'/MAC ADDRESS REMOVED/g'
tar -zcf "$filename.tar.gz" logs/*
rm -rf logs

if [ $DEPLOY_REPORT = "false" ]; then
  echo "Done! Logs saved to: $(readlink -f $filename.tar.gz)"
fi

if [ "$SEND_LOGS" = "true" ]; then
  if [ $DEPLOY_REPORT = "false" ]; then
    echo "Sending logs to 3mdeb."
  fi

  DPP_HCL_BUCKET="dasharo-hcl-reports"
  PUBLIC_HCL_BUCKET="dasharo-hcl-reports-public"

  if [ -f "${DPP_CREDENTIAL_FILE}" ]; then
    DPP_EMAIL=$(sed -n '1p' <${DPP_CREDENTIAL_FILE} | tr -d '\n')
    DPP_PASSWORD=$(sed -n '2p' <${DPP_CREDENTIAL_FILE} | tr -d '\n')

    if [ -z "$DPP_EMAIL" ]; then
      echo "DPP e-mail is empty"
      exit 1
    fi
    if [ -z "$(mc alias list | grep ${DPP_EMAIL})" ]; then
      if ! mc alias set $DPP_SERVER_USER_ALIAS $DPP_SERVER_ADDRESS $DPP_EMAIL $DPP_PASSWORD >>$ERR_LOG_FILE 2>&1; then
        exit 1
      fi
    fi
    DPP_HCL_LINK="${DPP_HCL_BUCKET}/${DPP_EMAIL}"
    ALIAS=$DPP_SERVER_USER_ALIAS
  else
    ALIAS="public-hcl"
    if [ -z "$(mc alias list | grep ${ALIAS})" ]; then
      if ! mc alias set $ALIAS $DPP_SERVER_ADDRESS $BASE_HCL_USERNAME $BASE_HCL_PASSWORD >>$ERR_LOG_FILE 2>&1; then
        exit 1
      fi
    fi
    DPP_HCL_LINK="${PUBLIC_HCL_BUCKET}"
  fi

  # Do not send HCLs when using mocks. Because in such case HCL will contain
  # only mocked information and will be useless. If such HCLs will be send every
  # time the testing with mocks is done - the HCLs database will soon be
  # polluted.
  if [ -z "$DTS_TESTING" ]; then
    mc cp "$(readlink -f $filename.tar.gz)" "${ALIAS}/${DPP_HCL_LINK}/"
  else
    echo "HCL will not be sent for mocked hardware."
  fi

  if [ "$?" -ne "0" ]; then
    echo "Failed to send logs to 3mdeb."
    exit 1
  fi
  if [ $DEPLOY_REPORT = "false" ]; then
    echo "Thank you for supporting Dasharo!"
  fi
fi

echo -e \
  "-----------------------------------------------------------------------------\r
Would you like to contribute to the \"Hardware for Linux\" project?\r
it is an open source project that that anonymously collects hardware details\r
of Linux-powered computers over the world and helps people to collaboratively\r
debug hardware related issues, check for Linux-compatibility and find drivers.\r
-----------------------------------------------------------------------------\r
You can find more about it here:\r
https://linux-hardware.org/\r
https://github.com/linuxhw/hw-probe\r
-----------------------------------------------------------------------------\r
Do you want to participate in this project?\r
(if you answer \"yes\", then command hw-probe --all --upload will be ran, in \r
order to participate)\r
"

if ask_for_confirmation; then
  $HW_PROBE -all -upload
  if [ $? -eq 0 ]; then
    echo "Thank you for contributing to the \"Hardware for Linux\" project!"
  else
    echo "couldn't probe/upload. Check your internet connection..."
    exit 1
  fi
else
  echo -e \
    "Please consider contributing to the \"Hardware for Linux\" project in the future.\r
    All you have to do is run this command:\r
    hw-probe --all --upload\r
    "
fi
