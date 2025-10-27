#!/bin/bash
# TUI Library for creating text-based user interfaces
# Requires: yq (YAML processor)

# ANSI color codes (matching DTS color scheme)
TUI_NORMAL='\033[0m'
TUI_RED='\033[0;31m'
TUI_GREEN='\033[0;32m'
TUI_YELLOW='\033[0;33m'
TUI_BLUE='\033[0;36m' # Cyan, used for borders (matches DTS BLUE)

# Terminal width configuration
TUI_MAX_WIDTH=60 # Maximum width for borders and footer wrapping

# Global variables
TUI_RUNNING=true

# Header variables
TUI_HEADER_TITLE=""
TUI_HEADER_SUBTITLE=""
TUI_HEADER_LINK=""

# Section arrays (using | as delimiter)
declare -a TUI_SECTIONS_DATA=() # condition|label
declare -a TUI_ENTRIES_DATA=()  # section_idx|condition|label|value

# Menu and footer arrays
declare -a TUI_MENU_DATA=()   # key|condition|label|callback
declare -a TUI_FOOTER_DATA=() # key|condition|label|callback

declare -A TUI_PRE_RENDER_CALLBACKS=()
declare -A TUI_POST_RENDER_CALLBACKS=()
# used to call callbacks in the same order as they were registered
TUI_PRE_RENDER_CALLBACKS_ORDER=()
TUI_POST_RENDER_CALLBACKS_ORDER=()

# Terminal control
tui_clear_screen() {
  printf '\033[2J\033[H'
}

tui_hide_cursor() {
  printf '\033[?25l'
}

tui_show_cursor() {
  printf '\033[?25h'
}

tui_clear_line() {
  printf '\r\033[K'
}

# Trap to ensure cursor is shown on exit
trap 'tui_show_cursor' EXIT INT TERM

# ============================================================================
# Utility Functions
# ============================================================================

# Calculate visible text length (stripping ANSI codes)
# Usage: tui_visible_length "text with ANSI codes"
tui_visible_length() {
  local text="$1"
  # Remove ANSI escape sequences and count characters
  echo -n "$text" | sed 's/\x1b\[[0-9;]*m//g' | wc -c
}

# Generate a border string of specified length with character
# Usage: tui_generate_border 80 "*"
tui_generate_border() {
  local length="$1"
  local char="${2:-*}"
  printf "%${length}s" | tr ' ' "$char"
}

# ============================================================================
# Color Echo Functions (DTS-compatible)
# ============================================================================

tui_echo_normal() {
  echo -e "${TUI_NORMAL}$1${TUI_NORMAL}"
}

tui_echo_red() {
  echo -e "${TUI_RED}$1${TUI_NORMAL}"
}

tui_echo_yellow() {
  echo -e "${TUI_YELLOW}$1${TUI_NORMAL}"
}

tui_echo_green() {
  echo -e "${TUI_GREEN}$1${TUI_NORMAL}"
}

tui_echo_blue() {
  echo -e "${TUI_BLUE}$1${TUI_NORMAL}"
}

# ============================================================================
# Status Message Functions
# ============================================================================

tui_print_warning() {
  tui_echo_yellow "Warning: $1"
}

tui_print_error() {
  tui_echo_red "Error: $1"
}

tui_print_success() {
  tui_echo_green "$1"
}

# ============================================================================
# Border and Layout Functions
# ============================================================================

# Print a full-width border line
# Usage: tui_print_border
tui_print_border() {
  local border
  border=$(tui_generate_border "$TUI_MAX_WIDTH" "*")
  echo -e "${TUI_BLUE}${border}${TUI_NORMAL}"
}

# Print the "**" prefix used in sections and menu items
# Usage: tui_print_border_prefix
tui_print_border_prefix() {
  echo -n -e "${TUI_BLUE}**${TUI_NORMAL}"
}

# ============================================================================
# Section Rendering Functions
# ============================================================================

# Print a section header with borders
# Usage: tui_print_section_header "SECTION LABEL"
tui_print_section_header() {
  local label="$1"
  tui_print_border
  echo -e "${TUI_BLUE}**${TUI_NORMAL}                $label ${TUI_NORMAL}"
  tui_print_border
}

# Print a section entry (label: value)
# Usage: tui_print_section_entry "Label" "Value"
tui_print_section_entry() {
  local label="$1"
  local value="$2"
  printf "${TUI_BLUE}**${TUI_YELLOW}%15s: ${TUI_NORMAL}%s\n" "$label" "$value"
}

# ============================================================================
# Menu Rendering Functions
# ============================================================================

# Print a menu option
# Usage: tui_print_menu_option "1" "Menu label"
tui_print_menu_option() {
  local key="$1"
  local label="$2"
  printf "${TUI_BLUE}**${TUI_YELLOW}     %s)${TUI_BLUE} %s${TUI_NORMAL}\n" "$key" "$label"
}

# ============================================================================
# Footer Rendering Functions
# ============================================================================

# Print a footer action (used internally by tui_render_footer)
# Usage: tui_print_footer_action "K" "label"
tui_print_footer_action() {
  local key="$1"
  local label="$2"
  echo -n -e "${TUI_RED}$key${TUI_NORMAL} to $label"
}

# ============================================================================
# Core Functions
# ============================================================================

# Expand environment variables in a string
# Usage: tui_expand_vars "string with $VAR"
tui_expand_vars() {
  local string="$1"
  # Use eval to expand variables, but safely quote the result
  eval "printf '%s' \"$string\""
}

# Check if a condition evaluates to true
# Conditions can be environment variable checks like: ${VAR} or ${VAR:-default}
# Usage: tui_check_condition "condition"
tui_check_condition() {
  local condition="$1"
  [[ -z "$condition" ]] && return 0 # No condition means always show

  # Expand and evaluate the condition
  local result
  result=$(eval echo "$condition" 2>/dev/null || echo "")

  # Check if result is non-empty and not "false" or "0"
  [[ -n "$result" && "$result" != "false" && "$result" != "0" ]]
}

# Load YAML configuration and parse into bash variables
# Usage: tui_load_config "config.yaml"
tui_load_config() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    echo "Error: Config file not found: $config_file" >&2
    return 1
  fi

  if ! command -v yq &>/dev/null; then
    echo "Error: yq is required but not installed" >&2
    echo "Install with: pip install yq  or  brew install yq" >&2
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed" >&2
    return 1
  fi

  # Convert YAML to JSON once
  local json_config
  json_config=$(yq eval -o=json "$config_file")

  # Parse header (using @ to safely handle special characters)
  TUI_HEADER_TITLE=$(echo "$json_config" | jq -r '.header.title // ""')
  TUI_HEADER_SUBTITLE=$(echo "$json_config" | jq -r '.header.subtitle // ""')
  TUI_HEADER_LINK=$(echo "$json_config" | jq -r '.header.link // ""')

  # Clear arrays
  TUI_SECTIONS_DATA=()
  TUI_ENTRIES_DATA=()
  TUI_MENU_DATA=()
  TUI_FOOTER_DATA=()

  # Parse sections
  local section_idx=0
  while IFS='|' read -r condition label; do
    if [[ -z "$label" && -z "$condition" ]]; then
      continue
    fi
    TUI_SECTIONS_DATA+=("$condition|$label")

    # Parse entries for this section
    while IFS='|' read -r entry_cond entry_label entry_value; do
      if [[ -z "$entry_label" && -z "$entry_value" ]]; then
        continue
      fi
      TUI_ENTRIES_DATA+=("$section_idx|$entry_cond|$entry_label|$entry_value")
    done < <(echo "$json_config" | jq -r ".sections[$section_idx].entries[]? | \"\(.condition // \"\")|\" + (.label | gsub(\"\\\\|\"; \"\\\\|\" )) + \"|\" + (.value | gsub(\"\\\\|\"; \"\\\\|\"))")

    ((section_idx++))
  done < <(echo "$json_config" | jq -r '.sections[]? | "\(.condition // "")|" + (.label | gsub("\\|"; "\\|"))')

  # Parse menu items
  while IFS='|' read -r key condition label callback; do
    if [[ -z "$key" ]]; then
      continue
    fi
    TUI_MENU_DATA+=("$key|$condition|$label|$callback")
  done < <(echo "$json_config" | jq -r '.menu[]? | .key + "|" + (.condition // "") + "|" + (.label | gsub("\\|"; "\\|")) + "|" + .callback')

  # Parse footer items
  while IFS='|' read -r key condition label callback; do
    if [[ -z "$key" ]]; then
      continue
    fi
    TUI_FOOTER_DATA+=("$key|$condition|$label|$callback")
  done < <(echo "$json_config" | jq -r '.footer[]? | .key + "|" + (.condition // "") + "|" + (.label | gsub("\\|"; "\\|")) + "|" + .callback')
}

# Render header section
tui_render_header() {
  if [[ -n "$TUI_HEADER_TITLE" ]]; then
    local title
    title=$(tui_expand_vars "$TUI_HEADER_TITLE")
    echo -e "${TUI_NORMAL}$title${TUI_NORMAL}"
  fi

  if [[ -n "$TUI_HEADER_SUBTITLE" ]]; then
    local subtitle
    subtitle=$(tui_expand_vars "$TUI_HEADER_SUBTITLE")
    echo -e "${TUI_NORMAL}$subtitle${TUI_NORMAL}"
  fi

  if [[ -n "$TUI_HEADER_LINK" ]]; then
    local link
    link=$(tui_expand_vars "$TUI_HEADER_LINK")
    echo -e "${TUI_NORMAL}Report issues at: $link${TUI_NORMAL}"
  fi
}

# Render all information sections
tui_render_info_sections() {
  local section_idx=0
  local section_data
  for section_data in "${TUI_SECTIONS_DATA[@]}"; do
    local condition label
    IFS='|' read -r condition label <<<"$section_data"

    # Check if section should be displayed
    if ! tui_check_condition "$condition"; then
      ((section_idx++))
      continue
    fi

    label=$(tui_expand_vars "$label")
    tui_print_section_header "$label"

    # Render entries for this section
    local entry_data
    for entry_data in "${TUI_ENTRIES_DATA[@]}"; do
      local entry_section_idx entry_condition entry_label entry_value
      IFS='|' read -r entry_section_idx entry_condition entry_label entry_value <<<"$entry_data"

      # Only render entries for this section
      if [[ "$entry_section_idx" != "$section_idx" ]]; then
        continue
      fi

      if ! tui_check_condition "$entry_condition"; then
        continue
      fi

      entry_label=$(tui_expand_vars "$entry_label")
      entry_value=$(tui_expand_vars "$entry_value")
      tui_print_section_entry "$entry_label" "$entry_value"
    done

    ((section_idx++))
  done
}

# Render main menu options
tui_render_menu() {
  if [[ ${#TUI_MENU_DATA[@]} -eq 0 ]]; then
    return 0
  fi

  tui_print_border
  local menu_item
  for menu_item in "${TUI_MENU_DATA[@]}"; do
    local key condition label callback
    IFS='|' read -r key condition label callback <<<"$menu_item"

    if ! tui_check_condition "$condition"; then
      continue
    fi

    label=$(tui_expand_vars "$label")
    tui_print_menu_option "$key" "$label"
  done
  tui_print_border
}

# Render footer actions with auto-wrap
tui_render_footer() {
  if [[ ${#TUI_FOOTER_DATA[@]} -eq 0 ]]; then
    return 0
  fi

  local footer_parts=()
  local footer_item

  # Build footer parts
  for footer_item in "${TUI_FOOTER_DATA[@]}"; do
    local key condition label callback
    IFS='|' read -r key condition label callback <<<"$footer_item"

    if ! tui_check_condition "$condition"; then
      continue
    fi

    label=$(tui_expand_vars "$label")
    footer_parts+=("${TUI_RED}$key${TUI_NORMAL} to $label")
  done

  if [[ ${#footer_parts[@]} -gt 0 ]]; then
    # Auto-wrap footer to multiple lines if needed
    local current_line=""
    local current_length=0
    local max_width=$((TUI_MAX_WIDTH - 2)) # Leave 2 chars margin

    for part in "${footer_parts[@]}"; do
      # Calculate visible length (strip ANSI codes)
      local visible_part
      visible_part=$(echo -e "$part" | sed 's/\x1b\[[0-9;]*m//g')
      local part_length=${#visible_part}

      # Add separator length if not first item on line
      local separator_length=0
      if [[ -n "$current_line" ]]; then
        separator_length=2 # "  " = 2 spaces
      fi

      # Check if adding this part would exceed max width
      if [[ -n "$current_line" ]] && ((current_length + separator_length + part_length > max_width)); then
        # Print current line and start new line
        echo -e "$current_line"
        current_line="$part"
        current_length=$part_length
      else
        # Add to current line
        if [[ -n "$current_line" ]]; then
          current_line+="  $part"
          current_length=$((current_length + separator_length + part_length))
        else
          current_line="$part"
          current_length=$part_length
        fi
      fi
    done

    # Print remaining line
    if [[ -n "$current_line" ]]; then
      echo -e "$current_line"
    fi
  fi
}

# Render complete menu
tui_render() {
  tui_clear_screen
  tui_render_header
  tui_render_info_sections
  tui_render_menu
  tui_render_footer
  echo ""
  echo -n -e "${TUI_YELLOW}Enter an option:${TUI_NORMAL}"
}

# Read a single keypress without waiting for Enter
# Returns the pressed key
tui_read_key() {
  local key
  read -n 1 -s key
  echo "$key"
}

# Print prompt and read user input
tui_read_prompt() {
  local prompt="$1"
  local answer
  echo -n "${prompt}: " >&2
  read -r answer
  echo "${answer}"
}

# Execute a callback script
# Usage: tui_execute_callback "script_path"
tui_execute_callback() {
  local script="$1"

  if [[ ! -f "$script" ]]; then
    echo "Error: Callback script not found: $script" >&2
    return 1
  fi

  if [[ ! -x "$script" ]]; then
    echo "Error: Callback script is not executable: $script" >&2
    return 1
  fi

  # Clear screen and execute callback
  tui_clear_screen

  # Execute the callback script
  "$script"
  local exit_code=$?

  # Wait for user to press a key before returning to menu
  echo ""
  echo -n "Press any key to continue..."
  tui_read_key

  return $exit_code
}

# Find menu item by key and return its callback
# Usage: tui_find_menu_callback "key"
tui_find_menu_callback() {
  local key="$1"

  for menu_item in "${TUI_MENU_DATA[@]}"; do
    IFS='|' read -r menu_key condition label callback <<<"$menu_item"

    if [[ "$menu_key" == "$key" ]]; then
      if tui_check_condition "$condition"; then
        # Expand environment variables in callback path
        callback=$(tui_expand_vars "$callback")
        echo "$callback"
        return 0
      fi
    fi
  done

  return 1
}

# Find footer item by key and return its callback
# Usage: tui_find_footer_callback "key"
tui_find_footer_callback() {
  local key="$1"

  for footer_item in "${TUI_FOOTER_DATA[@]}"; do
    IFS='|' read -r footer_key condition label callback <<<"$footer_item"

    if [[ "$footer_key" == "$key" ]]; then
      if tui_check_condition "$condition"; then
        # Expand environment variables in callback path
        callback=$(tui_expand_vars "$callback")
        echo "$callback"
        return 0
      fi
    fi
  done

  return 1
}

# Handle user input
# Returns: 0 to continue, 1 to exit
tui_handle_input() {
  local key
  key=$(tui_read_key)

  # Convert to uppercase for case-insensitive matching
  key=$(echo "$key" | tr '[:lower:]' '[:upper:]')

  # Hidden option: Q to quit (useful for testing)
  if [[ "$key" == "Q" ]]; then
    tui_stop
    return 0
  fi

  # Try to find callback in menu items
  local callback
  if callback=$(tui_find_menu_callback "$key"); then
    tui_execute_callback "$callback"
    return 0
  fi

  # Try to find callback in footer items
  if callback=$(tui_find_footer_callback "$key"); then
    tui_execute_callback "$callback"
    return 0
  fi

  # No matching option found
  return 0
}

# Main loop
# Usage: tui_run "config.yaml"
tui_run() {
  local config_file="$1"

  if ! tui_load_config "$config_file"; then
    return 1
  fi

  tui_hide_cursor
  TUI_RUNNING=true

  while $TUI_RUNNING; do
    for callback in "${TUI_PRE_RENDER_CALLBACKS_ORDER[@]}"; do
      eval "${callback}" "${TUI_PRE_RENDER_CALLBACKS["${callback}"]}"
    done
    tui_render
    for callback in "${TUI_POST_RENDER_CALLBACKS_ORDER[@]}"; do
      eval "${callback}" "${TUI_POST_RENDER_CALLBACKS["${callback}"]}"
    done
    tui_handle_input
  done

  tui_show_cursor
  tui_clear_screen
}

# Stop the TUI loop
tui_stop() {
  TUI_RUNNING=false
}

# register callbacks called during each UI refresh (before showing UI) e.g.
# tui_register_refresh_callback my_callback_func callback_arg_1 callback_arg_2
tui_register_pre_render_callback() {
  local callback="$1"
  shift
  TUI_PRE_RENDER_CALLBACKS["${callback}"]="$*"
  TUI_PRE_RENDER_CALLBACKS_ORDER+=("${callback}")
}

# register callbacks called during each UI refresh (after showing UI)
tui_register_post_render_callback() {
  local callback="$1"
  shift
  TUI_POST_RENDER_CALLBACKS["${callback}"]="$*"
  TUI_POST_RENDER_CALLBACKS_ORDER+=("${callback}")
}

# Export functions for use in other scripts

# Terminal control
export -f tui_clear_screen
export -f tui_hide_cursor
export -f tui_show_cursor

# Utility functions
export -f tui_visible_length
export -f tui_generate_border

# Color echo functions
export -f tui_echo_normal
export -f tui_echo_red
export -f tui_echo_yellow
export -f tui_echo_green
export -f tui_echo_blue

# Status message functions
export -f tui_print_warning
export -f tui_print_error
export -f tui_print_success

# Border and layout functions
export -f tui_print_border
export -f tui_print_border_prefix

# Section rendering functions
export -f tui_print_section_header
export -f tui_print_section_entry

# Menu rendering functions
export -f tui_print_menu_option

# Footer rendering functions
export -f tui_print_footer_action

# Core functions
export -f tui_expand_vars
export -f tui_check_condition
export -f tui_load_config
export -f tui_render_header
export -f tui_render_info_sections
export -f tui_render_menu
export -f tui_render_footer
export -f tui_render
export -f tui_read_key
export -f tui_execute_callback
export -f tui_find_menu_callback
export -f tui_find_footer_callback
export -f tui_handle_input
export -f tui_run
export -f tui_stop
