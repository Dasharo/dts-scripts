#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# ui-utils.sh - Utility functions for bash-ui-lib

# Prevent multiple sourcing
if [[ -n "${_UI_UTILS_SOURCED}" ]]; then
  return 0
fi
_UI_UTILS_SOURCED=1

# Source dependencies
UI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${UI_LIB_DIR}/ui-colors.sh"

# ui_read_single_char [prompt]
# Read a single character from user input
# Returns the character in UI_INPUT_CHAR variable
ui_read_single_char() {
  local prompt="${1:-}"
  UI_INPUT_CHAR=""

  if [[ -n "$prompt" ]]; then
    echo -ne "$prompt"
  fi

  read -r -n 1 UI_INPUT_CHAR
  echo
}

# ui_read_line [prompt]
# Read a line from user input
# Returns the line in UI_INPUT_LINE variable
ui_read_line() {
  local prompt="${1:-}"
  UI_INPUT_LINE=""

  if [[ -n "$prompt" ]]; then
    echo -ne "$prompt"
  fi

  read -r UI_INPUT_LINE
}

# ui_ask_yes_no <prompt> [default]
# Ask yes/no question
# Returns 0 for yes, 1 for no
# Default can be "y" or "n"
ui_ask_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  local yn_prompt="[y/n]"

  if [[ "$default" == "y" ]]; then
    yn_prompt="[Y/n]"
  elif [[ "$default" == "n" ]]; then
    yn_prompt="[y/N]"
  fi

  while true; do
    read -r -p "$prompt $yn_prompt: " response

    # Use default if response is empty
    if [[ -z "$response" ]]; then
      response="$default"
    fi

    case "$response" in
      [Yy]|[Yy][Ee][Ss])
        return 0
        ;;
      [Nn]|[Nn][Oo])
        return 1
        ;;
      *)
        ui_print_warning "Please answer yes or no."
        ;;
    esac
  done
}

# ui_ask_choice <prompt> [option1 description1] [option2 description2] ...
# Ask user to select from multiple choices
# Returns selected option key in UI_SELECTED_CHOICE variable
# Example: ui_ask_choice "Select action" "1" "Install" "2" "Update" "3" "Remove"
ui_ask_choice() {
  local prompt="$1"
  shift

  # Build associative array of choices
  declare -A choices
  local -a keys=()

  while [[ $# -gt 0 ]]; do
    local key="$1"
    local desc="$2"

    if [[ -z "$key" ]]; then
      shift 2
      continue
    fi

    choices["$key"]="$desc"
    keys+=("$key")
    shift 2
  done

  # Display prompt and options
  while true; do
    echo "$prompt"
    for key in "${keys[@]}"; do
      echo "  ${UI_THEME[MENU_KEY]}${key}${UI_COLORS[NORMAL]}: ${choices[$key]}"
    done
    echo

    read -r -p "Select an option: " UI_SELECTED_CHOICE
    echo

    # Check if choice is valid
    if [[ -n "$UI_SELECTED_CHOICE" && -n "${choices[$UI_SELECTED_CHOICE]+isset}" ]]; then
      return 0
    fi

    ui_print_warning "Invalid option. Please try again."
    echo
  done
}

# ui_confirm <message>
# Ask for confirmation before proceeding
# Returns 0 if confirmed, 1 otherwise
ui_confirm() {
  local message="$1"
  ui_ask_yes_no "$message" "n"
}

# ui_pause [message]
# Pause and wait for user to press Enter
ui_pause() {
  local message="${1:-Press Enter to continue.}"
  # Check if stdin is available and terminal is interactive
  if [[ -t 0 ]]; then
    read -r -p "$message" || true
  else
    # Non-interactive, just print message and return
    echo "$message"
  fi
}

# ui_wait_seconds <seconds> [message]
# Wait for specified seconds with countdown
ui_wait_seconds() {
  local seconds="$1"
  local message="${2:-Waiting}"

  for ((i = seconds; i > 0; i--)); do
    ui_clear_line
    echo -ne "${message} ${i}s..."
    sleep 1
  done
  ui_clear_line
  echo "${message} done."
}

# ui_progress_bar <current> <total> [width]
# Display a progress bar
# Example: ui_progress_bar 50 100 40
ui_progress_bar() {
  local current="$1"
  local total="$2"
  local width="${3:-50}"

  local percentage=$((current * 100 / total))
  local filled=$((current * width / total))
  local empty=$((width - filled))

  ui_clear_line
  printf "["
  printf "%${filled}s" | tr ' ' '='
  printf "%${empty}s" | tr ' ' ' '
  printf "] %3d%%\r" "$percentage"
}

# ui_spinner <pid> [message]
# Display a spinner while process is running
# Example: long_running_command & ui_spinner $! "Processing"
ui_spinner() {
  local pid="$1"
  local message="${2:-Processing}"
  local spin='|/-\'
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    i=$(((i + 1) % 4))
    printf "\r%s %c" "$message" "${spin:$i:1}"
    sleep 0.1
  done

  printf "\r%s done.\n" "$message"
}

# ui_draw_box <width> <text...>
# Draw a box around text
ui_draw_box() {
  local width="$1"
  shift
  local lines=("$@")

  # Top border
  echo -ne "${UI_THEME[BORDER]}"
  printf '+%*s+\n' "$((width))" '' | tr ' ' '-'

  # Content lines
  for line in "${lines[@]}"; do
    printf '| %-*s |\n' "$((width - 2))" "$line"
  done

  # Bottom border
  printf '+%*s+\n' "$((width))" '' | tr ' ' '-'
  echo -ne "${UI_COLORS[NORMAL]}"
}

# ui_draw_separator [char] [width]
# Draw a separator line
ui_draw_separator() {
  local char="${1:-=}"
  local width="${2:-60}"

  echo -ne "${UI_THEME[BORDER]}"
  printf '%*s\n' "$width" '' | tr ' ' "$char"
  echo -ne "${UI_COLORS[NORMAL]}"
}

# ui_center_text <text> [width]
# Center text within given width
ui_center_text() {
  local text="$1"
  local width="${2:-$(tput cols)}"
  local text_length=${#text}
  local padding=$(((width - text_length) / 2))

  printf "%*s%s\n" $padding "" "$text"
}

# ui_validate_not_empty <value> <field_name>
# Validate that value is not empty
# Returns 0 if valid, 1 if invalid
ui_validate_not_empty() {
  local value="$1"
  local field_name="$2"

  if [[ -z "$value" ]]; then
    ui_print_error "$field_name cannot be empty."
    return 1
  fi
  return 0
}

# ui_validate_number <value> <field_name>
# Validate that value is a number
# Returns 0 if valid, 1 if invalid
ui_validate_number() {
  local value="$1"
  local field_name="$2"

  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    ui_print_error "$field_name must be a number."
    return 1
  fi
  return 0
}

# ui_validate_range <value> <min> <max> <field_name>
# Validate that value is within range
# Returns 0 if valid, 1 if invalid
ui_validate_range() {
  local value="$1"
  local min="$2"
  local max="$3"
  local field_name="$4"

  if ! ui_validate_number "$value" "$field_name"; then
    return 1
  fi

  if [[ $value -lt $min || $value -gt $max ]]; then
    ui_print_error "$field_name must be between $min and $max."
    return 1
  fi
  return 0
}

# ui_get_terminal_size
# Get terminal width and height
# Sets UI_TERM_WIDTH and UI_TERM_HEIGHT variables
ui_get_terminal_size() {
  UI_TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
  UI_TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
}

# ui_is_interactive
# Check if running in interactive terminal
# Returns 0 if interactive, 1 otherwise
ui_is_interactive() {
  [[ -t 0 && -t 1 ]]
}

# ui_escape_ansi <text>
# Remove ANSI escape sequences from text
ui_escape_ansi() {
  local text="$1"
  # Handle both actual escape sequences and literal \033 strings
  echo "$text" | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\\033\[[0-9;]*m//g'
}

# ui_print_simple_line <text>
# Print a simple text line without formatting
# This is a primitive for backends to use instead of raw echo
ui_print_simple_line() {
  local text="$1"
  echo -e "${NORMAL}${text}${NORMAL}"
}

# ui_print_header_line <text>
# Print a header line with frame using separator character
# Format: **                TEXT
# Uses UI_SEPARATOR_CHAR (default: *) for frame
ui_print_header_line() {
  local text="$1"
  local sep_char="${UI_SEPARATOR_CHAR:-*}"
  echo -e "${BLUE}${sep_char}${sep_char}${NORMAL}${text}${NORMAL}"
}

# ui_print_information_line <label> <value>
# Print an information line with label and value
# Format: **     Label: Value
# Uses UI_SEPARATOR_CHAR (default: *) for frame
ui_print_information_line() {
  local label="$1"
  local value="$2"
  local sep_char="${UI_SEPARATOR_CHAR:-*}"
  echo -e "${BLUE}${sep_char}${sep_char}${YELLOW}${label}:${NORMAL} ${value}${NORMAL}"
}
