#!/usr/bin/env bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"
# shellcheck source=../../include/dts-functions.sh
source "$DTS_FUNCS"

if ! check_if_dasharo; then
  # flashrom does not support QEMU, but installation depends on flashrom.
  # TODO: this could be handled in a better way:
  [ "${SYSTEM_VENDOR}" = "QEMU" ] || [ "${SYSTEM_VENDOR}" = "Emulation" ] && exit 0

  if wait_for_network_connection; then
    tui_echo_normal "Preparing ..."
    if [ -z "${LOGS_SENT}" ]; then
      export SEND_LOGS="true"
      export DEPLOY_REPORT="true"
      if ! ${CMD_DASHARO_HCL_REPORT}; then
        tui_echo_normal "Unable to connect to dl.dasharo.com for submitting the
                       \rHCL report. Please recheck your internet connection."
      else
        LOGS_SENT="1"
      fi
    fi
  fi

  if [ -n "${LOGS_SENT}" ]; then
    ${CMD_DASHARO_DEPLOY} install
    result=$?
    if [ "$result" -ne $OK ] && [ "$result" -ne $CANCEL ]; then
      send_dts_logs ask && exit 0
    fi
  fi
else
  # TODO: This should be placed in dasharo-deploy:
  # For NovaCustom TGL laptops with Dasharo version lower than 1.3.0,
  # we shall run the ec_transition script instead. See:
  # https://docs.dasharo.com/variants/novacustom_nv4x_tgl/releases/#v130-2022-10-18
  if [ "$SYSTEM_VENDOR" = "Notebook" ]; then
    case "$SYSTEM_MODEL" in
    "NS50_70MU" | "NV4XMB,ME,MZ")
      compare_versions $DASHARO_VERSION 1.3.0
      if [ $? -eq 1 ]; then
        # For Dasharo version lesser than 1.3.0
        print_warning "Detected NovaCustom hardware with version < 1.3.0"
        print_warning "Need to perform EC transition after which the platform will turn off"
        print_warning "Then, please power it on and proceed with update again"
        print_warning "EC transition procedure will start in 5 seconds"
        sleep 5
        ${CMD_EC_TRANSITION}
        error_check "Could not perform EC transition"
      fi
      # Continue with regular update process for Dasharo version
      #  greater or equal 1.3.0
      ;;
    esac
  fi

  # Use regular update process for everything else
  ${CMD_DASHARO_DEPLOY} update
  result=$?
  if [ "$result" -ne $OK ] && [ "$result" -ne $CANCEL ]; then
    send_dts_logs ask && exit 0
  fi
fi
