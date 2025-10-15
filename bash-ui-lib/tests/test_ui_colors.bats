#!/usr/bin/env bats

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Tests for ui-colors.sh

setup() {
  # Load the library
  source "${BATS_TEST_DIRNAME}/../lib/ui-colors.sh"
}

@test "ui-colors.sh: library can be sourced" {
  [ -n "$_UI_COLORS_SOURCED" ]
}

@test "ui-colors.sh: prevents multiple sourcing" {
  local original_value="$_UI_COLORS_SOURCED"
  source "${BATS_TEST_DIRNAME}/../lib/ui-colors.sh"
  [ "$_UI_COLORS_SOURCED" = "$original_value" ]
}

@test "ui-colors.sh: UI_COLORS array is populated" {
  [ -n "${UI_COLORS[NORMAL]}" ]
  [ -n "${UI_COLORS[RED]}" ]
  [ -n "${UI_COLORS[GREEN]}" ]
  [ -n "${UI_COLORS[YELLOW]}" ]
  [ -n "${UI_COLORS[BLUE]}" ]
  [ -n "${UI_COLORS[CYAN]}" ]
}

@test "ui-colors.sh: UI_THEME array is populated" {
  [ -n "${UI_THEME[HEADER]}" ]
  [ -n "${UI_THEME[INFO]}" ]
  [ -n "${UI_THEME[SUCCESS]}" ]
  [ -n "${UI_THEME[WARNING]}" ]
  [ -n "${UI_THEME[ERROR]}" ]
}

@test "ui_color_echo: outputs colored text" {
  run ui_color_echo "${UI_COLORS[RED]}" "test message"
  [ "$status" -eq 0 ]
  [[ "$output" == *"test message"* ]]
}

@test "ui_echo_green: outputs text" {
  run ui_echo_green "green text"
  [ "$status" -eq 0 ]
  [[ "$output" == *"green text"* ]]
}

@test "ui_echo_red: outputs text" {
  run ui_echo_red "red text"
  [ "$status" -eq 0 ]
  [[ "$output" == *"red text"* ]]
}

@test "ui_echo_yellow: outputs text" {
  run ui_echo_yellow "yellow text"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yellow text"* ]]
}

@test "ui_echo_blue: outputs text" {
  run ui_echo_blue "blue text"
  [ "$status" -eq 0 ]
  [[ "$output" == *"blue text"* ]]
}

@test "ui_print_info: outputs text" {
  run ui_print_info "info message"
  [ "$status" -eq 0 ]
  [[ "$output" == *"info message"* ]]
}

@test "ui_print_success: outputs text" {
  run ui_print_success "success message"
  [ "$status" -eq 0 ]
  [[ "$output" == *"success message"* ]]
}

@test "ui_print_warning: outputs text" {
  run ui_print_warning "warning message"
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning message"* ]]
}

@test "ui_print_error: outputs text" {
  run ui_print_error "error message"
  [ "$status" -eq 0 ]
  [[ "$output" == *"error message"* ]]
}

@test "ui_set_theme_color: changes theme color" {
  local original="${UI_THEME[ERROR]}"
  ui_set_theme_color "ERROR" "${UI_COLORS[BLUE]}"
  [ "${UI_THEME[ERROR]}" = "${UI_COLORS[BLUE]}" ]
  # Restore
  ui_set_theme_color "ERROR" "$original"
}

@test "ui_disable_colors: removes color codes" {
  ui_disable_colors
  [ -z "${UI_COLORS[RED]}" ]
  [ -z "${UI_THEME[ERROR]}" ]
  # Restore
  source "${BATS_TEST_DIRNAME}/../lib/ui-colors.sh"
}

@test "ui_clear_line: executes without error" {
  run ui_clear_line
  [ "$status" -eq 0 ]
}

@test "ui_clear_screen: executes without error" {
  run ui_clear_screen
  [ "$status" -eq 0 ]
}

@test "ui_color_test: displays color test" {
  run ui_color_test
  [ "$status" -eq 0 ]
  [[ "$output" == *"Standard Colors"* ]]
  [[ "$output" == *"Bold Colors"* ]]
  [[ "$output" == *"Theme Colors"* ]]
}
