#!/bin/bash

# shellcheck disable=SC1090
DTS_ENV=/dev/null source "$DTS_FUNCS"

test_compare() {
  local -n array=$1
  local expected_value=$2

  for pair_str in "${array[@]}"; do
    read -ra pair <<<"$pair_str"
    echo "compare_versions ${pair[0]} ${pair[1]}"
    compare_versions "${pair[0]}" "${pair[1]}"
    compare=$?
    if [ $compare -ne "$expected_value" ]; then
      echo "ERROR: compare_versions ${pair[0]} ${pair[1]} returned $compare instead of $expected_value"
    fi
  done
}

# array of versions in format "ver1 ver2", where ver1 is less to ver2
# shellcheck disable=SC2034
less=(
  "2.0.0              3.0.0"
  "2.0.0              2.0.1"
  "2.0.2              2.1.0"
  "2.0.0-rc           2.0.0"
  "2.0.0-rc1          2.0.0"
  "2.0.0-rc1          2.0.1"
  "2.0.0-rc1          2.0.0-rc2"
  "2.0.0-rc2          2.0.0-rc12"
  "2.0.0-rc2          2.0.1-rc1"
  "2.0.0-rc.1         2.0.0-rc2"
  "2.0.0-rc1          2.0.0-rc.2"
  "2.0.0-rc.1         2.0.0-rc.2"
  "2.0.0-rc.2         2.0.0-rc12"
  "2.0.0-rc2          2.0.0-rc.12"
  # SeaBIOS versioning
  "24.08.00.05        24.08.00.07"
  "24.08.00.05        24.08.00.17"
  "24.05.00.05        24.08.00.01"
  "19.05.00           24.08.00.01"
  "19.05.00.05        24.08.00"
  "24.08.00.05-rc.1   24.08.00.05" # as of now doesn't work with SeaBIOS versioning
  "24.08.00.05-rc.1   24.08.00.05-rc.5"
)

# shellcheck disable=SC2034
greater_or_equal=(
  "2.0.0              2.0.0"
  "2.0.0-rc1          2.0.0-rc1"
  "2.0.0-rc.1         2.0.0-rc1"
  "2.0.0-rc1          2.0.0-rc.1"
  "3.0.0              2.0.0"
  "2.0.1              2.0.0"
  "2.0.1-rc1          2.0.0-rc2"
  "2.0.0-rc12         2.0.0-rc2"
  "2.0.0-rc.12        2.0.0-rc2"
  "2.0.0-rc12         2.0.0-rc.2"
  "24.08.00.05        24.08.00.05"
  "24.08.00.15        24.08.00.05"
  "24.09.00.02        24.08.00.05"
  "24.08.01.00        24.08.00"
  "24.08.01.05        24.08.01" # as of now doesn't work with SeaBIOS versioning
  "24.08.00.05-rc.1   24.08.00.04"
  "24.08.00.05-rc.10  24.08.00.05-rc.5"
)

echo "Starting test..."
test_compare less 1
test_compare greater_or_equal 0
echo "Test completed"
