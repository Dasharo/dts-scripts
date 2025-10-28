#!/bin/bash

# shellcheck source=../../include/dts-environment.sh
source "$DTS_ENV"

extensions_yaml="/tmp/extensions.yaml"
cat "${CONF_DIR}/header.yaml" >"${extensions_yaml}"
yq -i '. += {"menu": [], "footer": [{"key": "Q", "label": "go back"}]}' "${extensions_yaml}"

while IFS=$'\t' read -r file_name file_position _; do
  export file_name file_position callback
  callback="${DPP_PACKAGES_SCRIPTS_PATH}/${file_name}"
  yq -i '.menu += {"key": strenv(file_position), "label": strenv(file_name), "callback": strenv(callback)}' "$extensions_yaml"
done < <(yq -p=json '.[] | [.file_name, .file_menu_position] | @tsv' "${DPP_SUBMENU_JSON}")

tui_run "${extensions_yaml}"
