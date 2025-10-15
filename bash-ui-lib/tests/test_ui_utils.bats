#!/usr/bin/env bats

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Tests for ui-utils.sh

setup() {
  # Load the library
  source "${BATS_TEST_DIRNAME}/../lib/ui-utils.sh"
}

@test "ui-utils.sh: library can be sourced" {
  [ -n "$_UI_UTILS_SOURCED" ]
}

@test "ui-utils.sh: prevents multiple sourcing" {
  local original_value="$_UI_UTILS_SOURCED"
  source "${BATS_TEST_DIRNAME}/../lib/ui-utils.sh"
  [ "$_UI_UTILS_SOURCED" = "$original_value" ]
}

@test "ui_read_single_char: function exists" {
  type -t ui_read_single_char | grep -q "function"
}

@test "ui_read_line: function exists" {
  type -t ui_read_line | grep -q "function"
}

@test "ui_ask_yes_no: function exists" {
  type -t ui_ask_yes_no | grep -q "function"
}

@test "ui_ask_choice: function exists" {
  type -t ui_ask_choice | grep -q "function"
}

@test "ui_confirm: function exists" {
  type -t ui_confirm | grep -q "function"
}

@test "ui_pause: function exists" {
  type -t ui_pause | grep -q "function"
}

@test "ui_wait_seconds: function exists" {
  type -t ui_wait_seconds | grep -q "function"
}

@test "ui_progress_bar: displays progress" {
  run ui_progress_bar 50 100 40
  [ "$status" -eq 0 ]
}

@test "ui_spinner: function exists" {
  type -t ui_spinner | grep -q "function"
}

@test "ui_draw_box: draws a box" {
  run ui_draw_box 30 "Line 1" "Line 2" "Line 3"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Line 1"* ]]
  [[ "$output" == *"Line 2"* ]]
  [[ "$output" == *"Line 3"* ]]
}

@test "ui_draw_separator: draws separator" {
  run ui_draw_separator "=" 40
  [ "$status" -eq 0 ]
}

@test "ui_center_text: centers text" {
  run ui_center_text "Test" 20
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test"* ]]
}

@test "ui_validate_not_empty: returns 1 for empty string" {
  run ui_validate_not_empty "" "TestField"
  [ "$status" -eq 1 ]
}

@test "ui_validate_not_empty: returns 0 for non-empty string" {
  run ui_validate_not_empty "value" "TestField"
  [ "$status" -eq 0 ]
}

@test "ui_validate_number: returns 1 for non-number" {
  run ui_validate_number "abc" "TestField"
  [ "$status" -eq 1 ]
}

@test "ui_validate_number: returns 0 for valid number" {
  run ui_validate_number "123" "TestField"
  [ "$status" -eq 0 ]
}

@test "ui_validate_range: returns 1 for value below range" {
  run ui_validate_range 5 10 20 "TestField"
  [ "$status" -eq 1 ]
}

@test "ui_validate_range: returns 1 for value above range" {
  run ui_validate_range 25 10 20 "TestField"
  [ "$status" -eq 1 ]
}

@test "ui_validate_range: returns 0 for value in range" {
  run ui_validate_range 15 10 20 "TestField"
  [ "$status" -eq 0 ]
}

@test "ui_validate_range: returns 0 for boundary values" {
  run ui_validate_range 10 10 20 "TestField"
  [ "$status" -eq 0 ]
  run ui_validate_range 20 10 20 "TestField"
  [ "$status" -eq 0 ]
}

@test "ui_get_terminal_size: sets UI_TERM_WIDTH and UI_TERM_HEIGHT" {
  ui_get_terminal_size
  [ -n "$UI_TERM_WIDTH" ]
  [ -n "$UI_TERM_HEIGHT" ]
  [ "$UI_TERM_WIDTH" -gt 0 ]
  [ "$UI_TERM_HEIGHT" -gt 0 ]
}

@test "ui_is_interactive: function exists and runs" {
  # This might fail in CI, so just check it runs
  run ui_is_interactive
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "ui_escape_ansi: removes ANSI codes" {
  local text="${UI_COLORS[RED]}test${UI_COLORS[NORMAL]}"
  result=$(ui_escape_ansi "$text")
  [ "$result" = "test" ]
}

@test "ui_print_simple_line: prints simple text line" {
  run ui_print_simple_line "Test message"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Test message" ]]
}

@test "ui_print_header_line: prints header with frame" {
  run ui_print_header_line "TEST HEADER"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "**" ]]
  [[ "$output" =~ "TEST HEADER" ]]
}

@test "ui_print_information_line: prints label and value" {
  run ui_print_information_line "Label" "Value"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "**" ]]
  [[ "$output" =~ "Label:" ]]
  [[ "$output" =~ "Value" ]]
}

@test "ui_print_information_line: handles multi-word values" {
  run ui_print_information_line "System" "Test Vendor Test Model"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "System:" ]]
  [[ "$output" =~ "Test Vendor Test Model" ]]
}
