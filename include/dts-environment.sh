#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# shellcheck disable=SC2034

# Text colors:
NORMAL='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'

# DPP options:
DPP_SERVER_ADDRESS="https://dl.dasharo.com"
DPP_SERVER_USER_ALIAS="premium"
DPP_PACKAGE_MANAGER_DIR="/var/dasharo-package-manager"
DPP_AVAIL_PACKAGES_LIST="$DPP_PACKAGE_MANAGER_DIR/packages-list.json"
DPP_PACKAGES_SCRIPTS_PATH="$DPP_PACKAGE_MANAGER_DIR/packages-scripts"
DPP_SUBMENU_JSON="$DPP_PACKAGES_SCRIPTS_PATH/submenu.json"

# DTS options:
HCL_REPORT_OPT="1"
DASHARO_FIRM_OPT="2"
REST_FIRM_OPT="3"
DPP_KEYS_OPT="4"
DPP_SUBMENU_OPT="5"
BACK_TO_MAIN_MENU_UP="Q"
BACK_TO_MAIN_MENU_DOWN="$(echo $BACK_TO_MAIN_MENU_UP | awk '{print tolower($0)}')"
REBOOT_OPT_UP="R"
REBOOT_OPT_LOW="$(echo $REBOOT_OPT_UP | awk '{print tolower($0)}')"
POWEROFF_OPT_UP="P"
POWEROFF_OPT_LOW="$(echo $POWEROFF_OPT_UP | awk '{print tolower($0)}')"
SHELL_OPT_UP="S"
SHELL_OPT_LOW="$(echo $SHELL_OPT_UP | awk '{print tolower($0)}')"
SSH_OPT_UP="K"
SSH_OPT_LOW="$(echo $SSH_OPT_UP | awk '{print tolower($0)}')"
SEND_LOGS_OPT="L"
SEND_LOGS_OPT_LOW="$(echo $SEND_LOGS_OPT | awk '{print tolower($0)}')"
VERBOSE_OPT="V"
VERBOSE_OPT_LOW="$(echo $VERBOSE_OPT | awk '{print tolower($0)}')"

SYSTEM_VENDOR="${SYSTEM_VENDOR:-$(dmidecode -s system-manufacturer)}"
SYSTEM_MODEL="${SYSTEM_MODEL:-$(dmidecode -s system-product-name)}"
BOARD_VENDOR="${BOARD_VENDOR:-$(dmidecode -s system-manufacturer)}"
BOARD_MODEL="${BOARD_MODEL:-$(dmidecode -s baseboard-product-name)}"

CPU_VERSION="$(dmidecode -s processor-version)"
BIOS_VENDOR="${BIOS_VENDOR:-$(dmidecode -s bios-vendor)}"
BIOS_VERSION="${BIOS_VERSION:-$(dmidecode -s bios-version)}"
DASHARO_VERSION="$(echo $BIOS_VERSION | cut -d ' ' -f 3 | tr -d 'v')"
DASHARO_FLAVOR="$(echo $BIOS_VERSION | cut -d ' ' -f 1,2)"

# path to temporary files, created while deploying or updating Dasharo firmware
BIOS_UPDATE_FILE="/tmp/biosupdate.rom"
EC_UPDATE_FILE="/tmp/ecupdate.rom"
BIOS_HASH_FILE="/tmp/bioshash.sha256"
EC_HASH_FILE="/tmp/echash.sha256"
BIOS_SIGN_FILE="/tmp/biossignature.sig"
EC_SIGN_FILE="/tmp/ecsignature.sig"
BIOS_UPDATE_CONFIG_FILE="/tmp/biosupdate_config"
RESIGNED_BIOS_UPDATE_FILE="/tmp/biosupdate_resigned.rom"
SYSTEM_UUID_FILE="/tmp/system_uuid.txt"
SERIAL_NUMBER_FILE="/tmp/serial_number.txt"

# default value for flash chip related information
FLASH_CHIP_SELECT=""
FLASH_CHIP_SIZE=""

# dasharo-deploy backup cmd related variables, do we still use and need this as
# backup is placed in HCL?
ROOT_DIR="/"
FW_BACKUP_NAME="fw_backup"
FW_BACKUP_DIR="${ROOT_DIR}${FW_BACKUP_NAME}"
FW_BACKUP_TAR="${FW_BACKUP_DIR}.tar.gz"
FW_BACKUP_TAR="$(echo "$FW_BACKUP_TAR" | sed 's/\ /_/g')"

# path to system files
ERR_LOG_FILE="/var/local/dts-err.log"
FLASHROM_LOG_FILE="/var/local/flashrom.log"
FLASH_INFO_FILE="/tmp/flash_info"
OS_VERSION_FILE="/etc/os-release"
KEYS_DIR="/tmp/devkeys"

# path to system commands
CMD_POWEROFF="/sbin/poweroff"
CMD_REBOOT="/sbin/reboot"
CMD_SHELL="/bin/bash"
CMD_DASHARO_HCL_REPORT="/usr/sbin/dasharo-hcl-report"
CMD_NCMENU="/usr/sbin/novacustom_menu"
CMD_DASHARO_DEPLOY="/usr/sbin/dasharo-deploy"
CMD_CLOUD_LIST="/usr/sbin/cloud_list"
CMD_EC_TRANSITION="/usr/sbin/ec_transition"

# default values for flashrom programmer
FLASHROM="${FLASHROM:-flashrom}"
PROGRAMMER_BIOS="internal"
PROGRAMMER_EC="ite_ec"

DASHARO_ECTOOL="${DASHARO_ECTOOL:-dasharo_ectool}"

# variables defining Dasharo specific entries in DMI tables, used to check if
# Dasharo FW is already installed
DASHARO_VENDOR="3mdeb"
DASHARO_NAME="Dasharo"

# most the time one flash chipset will be detected, for other cases (like for
# ASUS KGPE-D16) we will test the following list in check_flash_chip function
FLASH_CHIP_LIST="W25Q64BV/W25Q64CV/W25Q64FV W25Q64JV-.Q W25Q128.V..M"

# Dasharo Supporters Entrance variables
DPP_credential_file="/etc/cloud-pass"
FW_STORE_URL="${FW_STORE_URL_DEV:-https://dl.3mdeb.com/open-source-firmware/Dasharo}"
FW_STORE_URL_DPP="https://cloud.3mdeb.com/public.php/webdav"
CLOUD_REQUEST="X-Requested-With: XMLHttpRequest"

## base values
BASE_CLOUDSEND_LOGS_URL="39d4biH4SkXD8Zm"
BASE_CLOUDSEND_PASSWORD="1{\[\k6G"
DEPLOY_REPORT="false"

BASE_DTS_LOGS_URL="xjBCYbzFdyq3WLt"
DTS_LOGS_PASSWORD="/w\J&<y1"

# set custom localization for PGP keys
if [ -d /home/root/.dasharo-gnupg ]; then
    GNUPGHOME=/home/root/.dasharo-gnupg

    export GNUPGHOME
fi
