#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

TMP_RESPONSE="/tmp/webdav_response"
TMP_LIST="/tmp/cloud_list"
HW_UUID="$1"

### Error checks
print_error() {
  echo -e "$RED""$1""$NORMAL"
}

error_exit() {
  _error_msg="$1"
  print_error "$_error_msg"
  exit 1
}

error_check() {
  _error_code=$?
  _error_msg="$1"
  [ "$_error_code" -ne 0 ] && error_exit "$_error_msg : ($_error_code)"
}

USER_DETAILS="$CLOUDSEND_LOGS_URL:$CLOUDSEND_PASSWORD"
CLOUD_REQUEST="X-Requested-With: XMLHttpRequest"

tmpURL="https://cloud.3mdeb.com/public.php/webdav/"

curl -L -f -u "$USER_DETAILS" -H "$CLOUD_REQUEST" -X PROPFIND "$tmpURL" -o "$TMP_RESPONSE" 2>>"$ERR_LOG_FILE"
error_check "Cannot access list of files on cloud."

# parse response
sed -i 's/\://g' "$TMP_RESPONSE"
sed -i 's/\?//g' "$TMP_RESPONSE"
sed -i 's/<dresponse>/&\n&\n<dresponse>/g' "$TMP_RESPONSE"
sed -i 's#<&/dresponse>#<&/dresponse>&\n#g' "$TMP_RESPONSE"

# create line per record
grep "public.php/webdav/" "$TMP_RESPONSE" >"$TMP_LIST"
# remove xml tags
sed -i 's#/dhref.*#\/dhref>#' "$TMP_LIST"
sed -i 's#<*dresponse>##g' "$TMP_LIST"
sed -i 's#<dhref>##g' "$TMP_LIST"
sed -i 's#</dhref>##g' "$TMP_LIST"
sed -i 's#/public.php/webdav/##g' "$TMP_LIST"

# get first, oldest HCL report with given UUID in name
HCL_REPORT_NAME=$(cat $TMP_LIST | grep -m1 $HW_UUID)

# download HCL report
tmpURL="https://cloud.3mdeb.com/public.php/webdav/$HCL_REPORT_NAME"
curl -L -f -u "$USER_DETAILS" -H "$CLOUD_REQUEST" -X GET "$tmpURL" -o /$HCL_REPORT_NAME 2>>"$ERR_LOG_FILE"
if [ -f /$HCL_REPORT_NAME ]; then
  echo "Report downloaded"
else
  echo "Report not found!"
  exit 1
fi
