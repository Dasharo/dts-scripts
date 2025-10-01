#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# ui-colors.sh - Color definitions and utilities for bash-ui-lib

# Prevent multiple sourcing
if [[ -n "${_UI_COLORS_SOURCED}" ]]; then
  return 0
fi
_UI_COLORS_SOURCED=1

# ANSI Color codes
declare -gA UI_COLORS=(
  [NORMAL]='\033[0m'
  [RESET]='\033[0m'
  [BOLD]='\033[1m'
  [DIM]='\033[2m'
  [UNDERLINE]='\033[4m'
  [BLINK]='\033[5m'
  [REVERSE]='\033[7m'
  [HIDDEN]='\033[8m'

  # Standard colors
  [BLACK]='\033[0;30m'
  [RED]='\033[0;31m'
  [GREEN]='\033[0;32m'
  [YELLOW]='\033[0;33m'
  [BLUE]='\033[0;34m'
  [MAGENTA]='\033[0;35m'
  [CYAN]='\033[0;36m'
  [WHITE]='\033[0;37m'

  # Bold colors
  [BOLD_BLACK]='\033[1;30m'
  [BOLD_RED]='\033[1;31m'
  [BOLD_GREEN]='\033[1;32m'
  [BOLD_YELLOW]='\033[1;33m'
  [BOLD_BLUE]='\033[1;34m'
  [BOLD_MAGENTA]='\033[1;35m'
  [BOLD_CYAN]='\033[1;36m'
  [BOLD_WHITE]='\033[1;37m'

  # Background colors
  [BG_BLACK]='\033[40m'
  [BG_RED]='\033[41m'
  [BG_GREEN]='\033[42m'
  [BG_YELLOW]='\033[43m'
  [BG_BLUE]='\033[44m'
  [BG_MAGENTA]='\033[45m'
  [BG_CYAN]='\033[46m'
  [BG_WHITE]='\033[47m'
)

# Color theme configuration
declare -gA UI_THEME=(
  [HEADER]="${UI_COLORS[NORMAL]}"
  [INFO]="${UI_COLORS[CYAN]}"
  [SUCCESS]="${UI_COLORS[GREEN]}"
  [WARNING]="${UI_COLORS[YELLOW]}"
  [ERROR]="${UI_COLORS[RED]}"
  [MENU_KEY]="${UI_COLORS[YELLOW]}"
  [MENU_TEXT]="${UI_COLORS[CYAN]}"
  [FOOTER_KEY]="${UI_COLORS[RED]}"
  [FOOTER_TEXT]="${UI_COLORS[NORMAL]}"
  [PROMPT]="${UI_COLORS[YELLOW]}"
  [BORDER]="${UI_COLORS[CYAN]}"
)

# ui_color_echo <color> <message>
# Print colored message
ui_color_echo() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${UI_COLORS[NORMAL]}"
}

# ui_echo_green <message>
# Print green message
ui_echo_green() {
  ui_color_echo "${UI_COLORS[GREEN]}" "$1"
}

# ui_echo_red <message>
# Print red message
ui_echo_red() {
  ui_color_echo "${UI_COLORS[RED]}" "$1"
}

# ui_echo_yellow <message>
# Print yellow message
ui_echo_yellow() {
  ui_color_echo "${UI_COLORS[YELLOW]}" "$1"
}

# ui_echo_blue <message>
# Print blue/cyan message
ui_echo_blue() {
  ui_color_echo "${UI_COLORS[CYAN]}" "$1"
}

# ui_print_info <message>
# Print info message using theme
ui_print_info() {
  ui_color_echo "${UI_THEME[INFO]}" "$1"
}

# ui_print_success <message>
# Print success message using theme
ui_print_success() {
  ui_color_echo "${UI_THEME[SUCCESS]}" "$1"
}

# ui_print_warning <message>
# Print warning message using theme
ui_print_warning() {
  ui_color_echo "${UI_THEME[WARNING]}" "$1"
}

# ui_print_error <message>
# Print error message using theme
ui_print_error() {
  ui_color_echo "${UI_THEME[ERROR]}" "$1"
}

# ui_set_theme_color <element> <color>
# Set theme color for specific element
# Example: ui_set_theme_color "MENU_KEY" "${UI_COLORS[BOLD_YELLOW]}"
ui_set_theme_color() {
  local element="$1"
  local color="$2"
  UI_THEME["$element"]="$color"
}

# ui_disable_colors
# Disable all colors (useful for non-interactive shells or logging)
ui_disable_colors() {
  for key in "${!UI_COLORS[@]}"; do
    UI_COLORS["$key"]=""
  done
  for key in "${!UI_THEME[@]}"; do
    UI_THEME["$key"]=""
  done
}

# ui_enable_colors
# Re-enable colors (restore defaults)
ui_enable_colors() {
  source "${BASH_SOURCE[0]}"
}

# ui_clear_line
# Clear current line (useful for progress indicators)
ui_clear_line() {
  printf '\r\033[K'
}

# ui_clear_screen
# Clear entire screen
ui_clear_screen() {
  clear
}

# ui_color_test
# Display all available colors (for testing)
ui_color_test() {
  echo "Standard Colors:"
  for color in BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
    ui_color_echo "${UI_COLORS[$color]}" "  $color"
  done

  echo ""
  echo "Bold Colors:"
  for color in BOLD_BLACK BOLD_RED BOLD_GREEN BOLD_YELLOW BOLD_BLUE BOLD_MAGENTA BOLD_CYAN BOLD_WHITE; do
    ui_color_echo "${UI_COLORS[$color]}" "  $color"
  done

  echo ""
  echo "Background Colors:"
  for color in BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_MAGENTA BG_CYAN BG_WHITE; do
    ui_color_echo "${UI_COLORS[$color]}" "  $color"
  done

  echo ""
  echo "Theme Colors:"
  echo -e "  INFO: ${UI_THEME[INFO]}Sample text${UI_COLORS[NORMAL]}"
  echo -e "  SUCCESS: ${UI_THEME[SUCCESS]}Sample text${UI_COLORS[NORMAL]}"
  echo -e "  WARNING: ${UI_THEME[WARNING]}Sample text${UI_COLORS[NORMAL]}"
  echo -e "  ERROR: ${UI_THEME[ERROR]}Sample text${UI_COLORS[NORMAL]}"
}
