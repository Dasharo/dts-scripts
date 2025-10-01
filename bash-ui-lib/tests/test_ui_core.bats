#!/usr/bin/env bats

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Tests for ui-core.sh

setup() {
  # Load the library
  source "${BATS_TEST_DIRNAME}/../lib/ui-core.sh"
}

teardown() {
  # Clean up after each test
  ui_clear_menu_items
  ui_clear_footer_actions
  UI_LOOP_RUNNING=0
}

@test "ui-core.sh: library can be sourced" {
  [ -n "$_UI_CORE_SOURCED" ]
}

@test "ui-core.sh: prevents multiple sourcing" {
  local original_value="$_UI_CORE_SOURCED"
  source "${BATS_TEST_DIRNAME}/../lib/ui-core.sh"
  [ "$_UI_CORE_SOURCED" = "$original_value" ]
}

@test "ui_init: initializes UI library" {
  run ui_init
  [ "$status" -eq 0 ]
}

@test "ui_set_input_mode: sets single character mode" {
  ui_set_input_mode "single"
  [ "$UI_INPUT_MODE" = "single" ]
}

@test "ui_set_input_mode: sets line mode" {
  ui_set_input_mode "line"
  [ "$UI_INPUT_MODE" = "line" ]
}

@test "ui_set_input_mode: rejects invalid mode" {
  run ui_set_input_mode "invalid"
  [ "$status" -eq 1 ]
}

@test "ui_set_pre_render_callback: sets callback" {
  ui_set_pre_render_callback "my_function"
  [ "$UI_PRE_RENDER_CALLBACK" = "my_function" ]
}

@test "ui_set_post_render_callback: sets callback" {
  ui_set_post_render_callback "my_function"
  [ "$UI_POST_RENDER_CALLBACK" = "my_function" ]
}

@test "ui_exit: stops the loop" {
  UI_LOOP_RUNNING=1
  ui_exit 0
  [ "$UI_LOOP_RUNNING" -eq 0 ]
  [ "$UI_LOOP_EXIT_CODE" -eq 0 ]
}

@test "ui_exit: sets exit code" {
  UI_LOOP_RUNNING=1
  ui_exit 42
  [ "$UI_LOOP_RUNNING" -eq 0 ]
  [ "$UI_LOOP_EXIT_CODE" -eq 42 ]
}

@test "ui_process_input: handles menu item" {
  test_handler() { echo "Menu handler"; }
  ui_add_menu_item "1" "Test" "test_handler"

  run ui_process_input "1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Menu handler"* ]]
}

@test "ui_process_input: handles footer action" {
  test_handler() { echo "Footer handler"; }
  ui_add_footer_action "Q" "Quit" "test_handler"

  run ui_process_input "Q"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Footer handler"* ]]
}

@test "ui_process_input: handles case insensitive footer actions" {
  test_handler() { echo "Case insensitive"; }
  ui_add_footer_action "Q" "Quit" "test_handler"

  run ui_process_input "q"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Case insensitive"* ]]
}

@test "ui_process_input: returns 1 for unknown input" {
  run ui_process_input "Z"
  [ "$status" -eq 1 ]
}

@test "ui_action_exit: exits with code 0" {
  UI_LOOP_RUNNING=1
  ui_action_exit
  [ "$UI_LOOP_RUNNING" -eq 0 ]
  [ "$UI_LOOP_EXIT_CODE" -eq 0 ]
}

@test "ui_action_back: exits with code 0" {
  UI_LOOP_RUNNING=1
  ui_action_back
  [ "$UI_LOOP_RUNNING" -eq 0 ]
  [ "$UI_LOOP_EXIT_CODE" -eq 0 ]
}

@test "ui_action_shell: function exists" {
  type -t ui_action_shell | grep -q "function"
}

@test "ui_action_reboot: function exists" {
  type -t ui_action_reboot | grep -q "function"
}

@test "ui_action_poweroff: function exists" {
  type -t ui_action_poweroff | grep -q "function"
}

@test "ui_run_external_command: runs command" {
  # Mock ui_pause to avoid waiting for input in tests
  ui_pause() { :; }
  export -f ui_pause

  run ui_run_external_command echo "test output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"test output"* ]]
}

@test "ui_run_external_command: returns command exit code" {
  # Mock ui_pause to avoid waiting for input in tests
  ui_pause() { :; }
  export -f ui_pause

  run ui_run_external_command false
  [ "$status" -eq 1 ]
}

@test "ui_simple_menu_header: renders header" {
  UI_SIMPLE_MENU_TITLE="Test Menu"
  run ui_simple_menu_header
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test Menu"* ]]
}
