# Quick Start Guide

Get up and running with bash-ui-lib in 5 minutes!

## Installation

```bash
# Clone or copy the library to your project
cp -r bash-ui-lib/lib /path/to/your/project/
```

## Your First Menu

Create a file `my-menu.sh`:

```bash
#!/usr/bin/env bash

# Source the library
source "lib/ui-core.sh"

# Define what happens when option is selected
greet_handler() {
  ui_clear_screen
  ui_print_success "Hello from bash-ui-lib!"
  echo
  ui_pause
}

# Add menu item: key "1", text "Greet", handler "greet_handler"
ui_add_menu_item "1" "Say Hello" "greet_handler"

# Add quit action
ui_add_footer_action "Q" "quit" "ui_action_exit"

# Start the menu
ui_main_loop
```

Make it executable and run:
```bash
chmod +x my-menu.sh
./my-menu.sh
```

## Common Patterns

### Multiple Menu Options

```bash
option1() {
  ui_clear_screen
  ui_print_info "Option 1 selected"
  ui_pause
}

option2() {
  ui_clear_screen
  ui_print_info "Option 2 selected"
  ui_pause
}

ui_add_menu_item "1" "First Option" "option1"
ui_add_menu_item "2" "Second Option" "option2"
ui_add_footer_action "Q" "quit" "ui_action_exit"

ui_main_loop
```

### Asking for Confirmation

```bash
delete_handler() {
  if ui_confirm "Are you sure you want to delete?"; then
    ui_print_success "Deleted!"
  else
    ui_print_warning "Cancelled"
  fi
  echo
  ui_pause
}
```

### Multiple Choice

```bash
select_handler() {
  ui_clear_screen

  ui_ask_choice "Select a color" \
    "r" "Red" \
    "g" "Green" \
    "b" "Blue"

  ui_print_info "You selected: $UI_SELECTED_CHOICE"
  echo
  ui_pause
}
```

### Conditional Menu Items

```bash
# Define condition function
is_admin() {
  [[ $EUID -eq 0 ]]
}

# Only show if running as root
ui_add_menu_item "9" "Admin Function" "admin_handler" "is_admin"
```

### Custom Header

```bash
my_header() {
  ui_render_default_header "My Application" "Version 1.0"
}

ui_set_header_callback "my_header"
```

### Running External Commands

```bash
run_ls_handler() {
  ui_run_external_command ls -la
}

ui_add_menu_item "1" "List Files" "run_ls_handler"
```

## Real-World Example

Complete system management menu:

```bash
#!/usr/bin/env bash

source "lib/ui-core.sh"

# Application state
FEATURE_ENABLED=false

# Handlers
enable_feature() {
  FEATURE_ENABLED=true
  ui_print_success "Feature enabled"
  ui_pause
}

disable_feature() {
  FEATURE_ENABLED=false
  ui_print_warning "Feature disabled"
  ui_pause
}

show_status() {
  ui_clear_screen
  ui_print_info "Status Report"
  echo "Feature: $FEATURE_ENABLED"
  echo "User: $(whoami)"
  echo "Date: $(date)"
  ui_pause
}

# Conditions
is_enabled() { [[ "$FEATURE_ENABLED" == "true" ]]; }
is_disabled() { [[ "$FEATURE_ENABLED" == "false" ]]; }

# Custom header
my_header() {
  ui_render_default_header "System Manager"
  echo "Feature Status: $FEATURE_ENABLED"
  ui_render_separator
}

# Setup
ui_set_header_callback "my_header"

ui_add_menu_item "1" "Enable Feature" "enable_feature" "is_disabled"
ui_add_menu_item "2" "Disable Feature" "disable_feature" "is_enabled"
ui_add_menu_item "3" "Show Status" "show_status"

ui_add_footer_action "Q" "quit" "ui_action_exit"
ui_add_footer_action "S" "shell" "ui_action_shell"

# Run
ui_main_loop
```

## Next Steps

1. **Check out the examples**: `examples/simple-menu.sh` and `examples/advanced-menu.sh`
2. **Read the full API**: See `README.md` for complete function reference
3. **Write tests**: Use BATS to test your menu logic
4. **Explore utilities**: Check out progress bars, spinners, and validation functions

## Common Functions Quick Reference

### Output
```bash
ui_print_info "Information message"
ui_print_success "Success message"
ui_print_warning "Warning message"
ui_print_error "Error message"
```

### User Input
```bash
ui_confirm "Continue?"                    # Yes/no
ui_ask_yes_no "Proceed?" "y"             # With default
ui_ask_choice "Pick" "1" "Opt 1" "2" "Opt 2"  # Multiple choice
ui_pause                                  # Wait for Enter
```

### Visual
```bash
ui_clear_screen                           # Clear screen
ui_draw_separator "=" 60                  # Draw line
ui_draw_box 40 "Line 1" "Line 2"         # Draw box
ui_progress_bar 50 100                    # Progress bar
```

### Validation
```bash
ui_validate_not_empty "$var" "Field"     # Not empty
ui_validate_number "$var" "Field"        # Is number
ui_validate_range "$var" 1 100 "Field"   # In range
```

## Tips

1. Always call `ui_clear_screen` at the start of handlers
2. Always call `ui_pause` at the end to let users read output
3. Use conditions to create dynamic menus
4. Validate all user input
5. Handle errors gracefully

## Getting Help

- Full documentation: `README.md`
- Testing guide: `docs/TESTING.md`
- Examples: `examples/` directory
- Issues: https://github.com/Dasharo/dasharo-issues

Happy coding!
