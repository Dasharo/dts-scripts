#!/usr/bin/env bats

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Tests for ui-render.sh

setup() {
  # Load the library
  source "${BATS_TEST_DIRNAME}/../lib/ui-render.sh"
}

teardown() {
  # Clean up menu items and footer actions after each test
  ui_clear_menu_items
  ui_clear_footer_actions
}

@test "ui-render.sh: library can be sourced" {
  [ -n "$_UI_RENDER_SOURCED" ]
}

@test "ui-render.sh: prevents multiple sourcing" {
  local original_value="$_UI_RENDER_SOURCED"
  source "${BATS_TEST_DIRNAME}/../lib/ui-render.sh"
  [ "$_UI_RENDER_SOURCED" = "$original_value" ]
}

@test "ui_add_menu_item: adds menu item" {
  ui_add_menu_item "1" "Test Option" "test_handler"
  [ "${UI_MENU_ITEMS_TEXT[1]}" = "Test Option" ]
  [ "${UI_MENU_ITEMS_HANDLER[1]}" = "test_handler" ]
  [[ " ${UI_MENU_ITEMS_KEYS[*]} " =~ " 1 " ]]
}

@test "ui_add_menu_item: fails without required parameters" {
  run ui_add_menu_item "1" ""
  [ "$status" -eq 1 ]
}

@test "ui_add_menu_item: adds menu item with condition" {
  ui_add_menu_item "1" "Test Option" "test_handler" "test_condition"
  [ "${UI_MENU_ITEMS_CONDITION[1]}" = "test_condition" ]
}

@test "ui_remove_menu_item: removes menu item" {
  ui_add_menu_item "1" "Test Option" "test_handler"
  ui_remove_menu_item "1"
  [[ ! " ${UI_MENU_ITEMS_KEYS[*]} " =~ " 1 " ]]
}

@test "ui_clear_menu_items: clears all menu items" {
  ui_add_menu_item "1" "Option 1" "handler1"
  ui_add_menu_item "2" "Option 2" "handler2"
  ui_clear_menu_items
  [ "${#UI_MENU_ITEMS_KEYS[@]}" -eq 0 ]
}

@test "ui_add_footer_action: adds footer action" {
  ui_add_footer_action "Q" "Quit" "exit_handler"
  [ "${UI_FOOTER_ACTIONS_TEXT[Q]}" = "Quit" ]
  [ "${UI_FOOTER_ACTIONS_HANDLER[Q]}" = "exit_handler" ]
  [[ " ${UI_FOOTER_ACTIONS_KEYS[*]} " =~ " Q " ]]
}

@test "ui_add_footer_action: fails without required parameters" {
  run ui_add_footer_action "Q" ""
  [ "$status" -eq 1 ]
}

@test "ui_add_footer_action: adds footer action with condition" {
  ui_add_footer_action "R" "Reboot" "reboot_handler" "is_root"
  [ "${UI_FOOTER_ACTIONS_CONDITION[R]}" = "is_root" ]
}

@test "ui_remove_footer_action: removes footer action" {
  ui_add_footer_action "Q" "Quit" "exit_handler"
  ui_remove_footer_action "Q"
  [[ ! " ${UI_FOOTER_ACTIONS_KEYS[*]} " =~ " Q " ]]
}

@test "ui_clear_footer_actions: clears all footer actions" {
  ui_add_footer_action "Q" "Quit" "exit_handler"
  ui_add_footer_action "R" "Reboot" "reboot_handler"
  ui_clear_footer_actions
  [ "${#UI_FOOTER_ACTIONS_KEYS[@]}" -eq 0 ]
}

@test "ui_set_header_callback: sets callback" {
  ui_set_header_callback "my_header_function"
  [ "$UI_HEADER_CALLBACK" = "my_header_function" ]
}

@test "ui_set_footer_callback: sets callback" {
  ui_set_footer_callback "my_footer_function"
  [ "$UI_FOOTER_CALLBACK" = "my_footer_function" ]
}

@test "ui_set_info_section_callback: sets callback" {
  ui_set_info_section_callback "my_info_function"
  [ "$UI_INFO_SECTION_CALLBACK" = "my_info_function" ]
}

@test "ui_render_separator: renders separator" {
  run ui_render_separator
  [ "$status" -eq 0 ]
}

@test "ui_render_default_header: renders header with title" {
  run ui_render_default_header "Test Title"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test Title"* ]]
}

@test "ui_render_default_header: renders header with title and subtitle" {
  run ui_render_default_header "Test Title" "Test Subtitle"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test Title"* ]]
  [[ "$output" == *"Test Subtitle"* ]]
}

@test "ui_render_header: calls default header when no callback set" {
  UI_HEADER_CALLBACK=""
  run ui_render_header
  [ "$status" -eq 0 ]
  [[ "$output" == *"Menu"* ]]
}

@test "ui_render_header: calls custom callback when set" {
  custom_header() { echo "Custom Header"; }
  ui_set_header_callback "custom_header"
  run ui_render_header
  [ "$status" -eq 0 ]
  [[ "$output" == *"Custom Header"* ]]
}

@test "ui_render_menu: renders menu items" {
  ui_add_menu_item "1" "Option 1" "handler1"
  ui_add_menu_item "2" "Option 2" "handler2"
  run ui_render_menu
  [ "$status" -eq 0 ]
  [[ "$output" == *"Option 1"* ]]
  [[ "$output" == *"Option 2"* ]]
}

@test "ui_render_menu: shows message when no items" {
  ui_clear_menu_items
  run ui_render_menu
  [ "$status" -eq 0 ]
  [[ "$output" == *"No menu items"* ]]
}

@test "ui_render_menu: respects conditions" {
  condition_true() { return 0; }
  condition_false() { return 1; }

  ui_add_menu_item "1" "Visible Option" "handler1" "condition_true"
  ui_add_menu_item "2" "Hidden Option" "handler2" "condition_false"

  run ui_render_menu
  [ "$status" -eq 0 ]
  [[ "$output" == *"Visible Option"* ]]
  [[ "$output" != *"Hidden Option"* ]]
}

@test "ui_render_default_footer: renders footer actions" {
  ui_add_footer_action "Q" "Quit" "exit_handler"
  ui_add_footer_action "R" "Reboot" "reboot_handler"
  run ui_render_default_footer
  [ "$status" -eq 0 ]
  [[ "$output" == *"Quit"* ]]
  [[ "$output" == *"Reboot"* ]]
}

@test "ui_render_footer: calls default footer when no callback set" {
  UI_FOOTER_CALLBACK=""
  ui_add_footer_action "Q" "Quit" "exit_handler"
  run ui_render_footer
  [ "$status" -eq 0 ]
  [[ "$output" == *"Quit"* ]]
}

@test "ui_render_footer: calls custom callback when set" {
  custom_footer() { echo "Custom Footer"; }
  ui_set_footer_callback "custom_footer"
  run ui_render_footer
  [ "$status" -eq 0 ]
  [[ "$output" == *"Custom Footer"* ]]
}

@test "ui_handle_menu_selection: returns 1 for non-existent key" {
  run ui_handle_menu_selection "999"
  [ "$status" -eq 1 ]
}

@test "ui_handle_menu_selection: calls handler for valid key" {
  test_handler() { echo "Handler called"; }
  ui_add_menu_item "1" "Test" "test_handler"
  run ui_handle_menu_selection "1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Handler called"* ]]
}

@test "ui_handle_menu_selection: respects condition" {
  condition_false() { return 1; }
  test_handler() { echo "Handler called"; }
  ui_add_menu_item "1" "Test" "test_handler" "condition_false"
  run ui_handle_menu_selection "1"
  [ "$status" -eq 1 ]
}

@test "ui_handle_footer_selection: returns 1 for non-existent key" {
  run ui_handle_footer_selection "Z"
  [ "$status" -eq 1 ]
}

@test "ui_handle_footer_selection: calls handler for valid key" {
  test_handler() { echo "Footer handler called"; }
  ui_add_footer_action "Q" "Quit" "test_handler"
  run ui_handle_footer_selection "Q"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Footer handler called"* ]]
}

@test "ui_handle_footer_selection: respects condition" {
  condition_false() { return 1; }
  test_handler() { echo "Handler called"; }
  ui_add_footer_action "R" "Reboot" "test_handler" "condition_false"
  run ui_handle_footer_selection "R"
  [ "$status" -eq 1 ]
}
