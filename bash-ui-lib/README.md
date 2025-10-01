# bash-ui-lib

A reusable Bash library for creating interactive text-based user interfaces with menus, prompts, and color support.

## Features

- **Simple Menu System**: Easy-to-use API for creating interactive menus
- **Color Support**: Rich color themes and customizable color schemes
- **Utility Functions**: Input validation, progress bars, spinners, and more
- **Conditional Menu Items**: Show/hide menu items based on conditions
- **Submenus**: Support for nested menu structures
- **Customizable**: Override default rendering with custom callbacks
- **Well-Tested**: Comprehensive test suite using BATS
- **Safe**: Gracefully handles non-interactive terminals

## Installation

Simply clone or copy the `bash-ui-lib` directory to your project:

```bash
# Clone the repository
git clone <repository-url>

# Or copy the lib directory to your project
cp -r bash-ui-lib/lib /path/to/your/project/
```

## Requirements

- **Interactive Terminal**: The library requires a TTY (interactive terminal) to function properly
- **Bash 4.0+**: Uses associative arrays and other modern bash features
- **Standard utilities**: `tput`, `grep`, `sed` (usually pre-installed)

**Note**: The library will detect non-interactive terminals and exit gracefully with appropriate warnings.

## Quick Start

Here's a minimal example:

```bash
#!/usr/bin/env bash

# Source the library
source "lib/ui-core.sh"

# Define handlers
option1_handler() {
  ui_clear_screen
  ui_print_success "You selected option 1!"
  ui_pause
}

# Set up menu
ui_add_menu_item "1" "First Option" "option1_handler"
ui_add_footer_action "Q" "quit" "ui_action_exit"

# Run menu
ui_main_loop
```

## Library Components

### ui-colors.sh
Color definitions and themed output functions.

- `ui_echo_green`, `ui_echo_red`, `ui_echo_yellow`, `ui_echo_blue`
- `ui_print_info`, `ui_print_success`, `ui_print_warning`, `ui_print_error`
- `ui_set_theme_color` - Customize color theme
- `ui_disable_colors` / `ui_enable_colors` - Toggle colors

### ui-utils.sh
Utility functions for user interaction.

- `ui_ask_yes_no` - Ask yes/no questions
- `ui_ask_choice` - Multi-choice selection
- `ui_confirm` - Confirmation prompts
- `ui_pause` - Wait for user input
- `ui_progress_bar` - Display progress
- `ui_spinner` - Show spinner animation
- `ui_draw_box` - Draw text boxes
- `ui_validate_*` - Input validation functions

### ui-render.sh
Menu rendering and management.

- `ui_add_menu_item` - Add menu items
- `ui_add_footer_action` - Add footer actions
- `ui_set_header_callback` - Custom header
- `ui_set_info_section_callback` - Custom info section
- `ui_render_screen` - Render complete UI

### ui-core.sh
Main loop and event handling.

- `ui_main_loop` - Start the UI loop
- `ui_exit` - Exit the UI loop
- `ui_set_input_mode` - Single char or line input
- `ui_action_*` - Built-in action handlers

## API Reference

### Menu Management

#### ui_add_menu_item
```bash
ui_add_menu_item <key> <text> <handler> [condition_function]
```
Add a menu item.
- `key`: Single character or string for selection
- `text`: Display text for the menu item
- `handler`: Function to call when selected
- `condition_function`: Optional function that returns 0 to show item

Example:
```bash
ui_add_menu_item "1" "Install Software" "install_handler"
ui_add_menu_item "2" "Update Software" "update_handler" "is_installed"
```

#### ui_remove_menu_item
```bash
ui_remove_menu_item <key>
```
Remove a menu item.

#### ui_clear_menu_items
```bash
ui_clear_menu_items
```
Clear all menu items.

### Footer Actions

#### ui_add_footer_action
```bash
ui_add_footer_action <key> <text> <handler> [condition_function]
```
Add a footer action (similar to menu items).

Example:
```bash
ui_add_footer_action "Q" "quit" "ui_action_exit"
ui_add_footer_action "R" "reboot" "ui_action_reboot"
```

### Customization

#### ui_set_header_callback
```bash
ui_set_header_callback <function_name>
```
Set custom header rendering function.

Example:
```bash
my_header() {
  ui_render_default_header "My App" "v1.0.0"
}
ui_set_header_callback "my_header"
```

#### ui_set_info_section_callback
```bash
ui_set_info_section_callback <function_name>
```
Set custom info section (displayed between header and menu).

#### ui_set_footer_callback
```bash
ui_set_footer_callback <function_name>
```
Set custom footer rendering function.

### User Input

#### ui_ask_yes_no
```bash
ui_ask_yes_no <prompt> [default]
```
Returns 0 for yes, 1 for no.

Example:
```bash
if ui_ask_yes_no "Continue?" "y"; then
  echo "Continuing..."
fi
```

#### ui_ask_choice
```bash
ui_ask_choice <prompt> <key1> <text1> <key2> <text2> ...
```
Sets `UI_SELECTED_CHOICE` variable with selected key.

Example:
```bash
ui_ask_choice "Select option" "1" "Option A" "2" "Option B"
echo "You selected: $UI_SELECTED_CHOICE"
```

#### ui_confirm
```bash
ui_confirm <message>
```
Returns 0 if confirmed, 1 otherwise.

### Visual Elements

#### ui_progress_bar
```bash
ui_progress_bar <current> <total> [width]
```

Example:
```bash
for i in {1..100}; do
  ui_progress_bar $i 100 50
  sleep 0.1
done
```

#### ui_draw_box
```bash
ui_draw_box <width> <line1> [line2] ...
```

Example:
```bash
ui_draw_box 40 "Welcome!" "Please select an option" "from the menu below"
```

#### ui_draw_separator
```bash
ui_draw_separator [char] [width]
```

Example:
```bash
ui_draw_separator "=" 60
```

### Validation

#### ui_validate_not_empty
```bash
ui_validate_not_empty <value> <field_name>
```

#### ui_validate_number
```bash
ui_validate_number <value> <field_name>
```

#### ui_validate_range
```bash
ui_validate_range <value> <min> <max> <field_name>
```

Example:
```bash
read -p "Enter age: " age
if ui_validate_range "$age" 1 120 "Age"; then
  echo "Valid age"
fi
```

## Testing

The library includes a comprehensive test suite using BATS (Bash Automated Testing System).

### Running Tests

```bash
# Install bats-core
# Debian/Ubuntu:
sudo apt-get install bats

# Fedora:
sudo dnf install bats

# Run all tests
cd bash-ui-lib/tests
./run_tests.sh
```

### Test Coverage

- `test_ui_colors.bats` - Color system tests
- `test_ui_utils.bats` - Utility function tests
- `test_ui_render.bats` - Rendering system tests
- `test_ui_core.bats` - Core functionality tests

## Examples

See the `examples/` directory for complete working examples:

- `simple-menu.sh` - Basic menu example
- `advanced-menu.sh` - Advanced features (submenus, conditions, themes)

Run examples:
```bash
./examples/simple-menu.sh
./examples/advanced-menu.sh
```

## DTS Integration

For integrating with existing DTS (Dasharo Tools Suite) code, use the adapter:

```bash
source "lib/dts-ui-adapter.sh"

# Now you can use both DTS functions and ui-lib functions
echo_green "Hello"           # DTS style
ui_echo_green "Hello"        # UI lib style

# Set up DTS-style UI
dts_setup_ui
dts_register_menu_item "1" "Option 1" "handler1"
ui_main_loop
```

## Architecture

```
bash-ui-lib/
├── lib/
│   ├── ui-core.sh         # Main loop and event handling
│   ├── ui-render.sh       # Menu rendering and management
│   ├── ui-utils.sh        # Utility functions
│   ├── ui-colors.sh       # Color definitions
│   └── dts-ui-adapter.sh  # DTS compatibility layer
├── tests/
│   ├── test_ui_*.bats     # BATS test files
│   └── run_tests.sh       # Test runner
├── examples/
│   ├── simple-menu.sh     # Simple example
│   └── advanced-menu.sh   # Advanced example
└── README.md              # This file
```

## Best Practices

1. **Always define handlers before adding menu items**
2. **Use conditions for dynamic menus** - Show/hide items based on state
3. **Clear screen in handlers** - Start with `ui_clear_screen` for clean output
4. **Always pause after output** - Use `ui_pause` to let users read messages
5. **Validate user input** - Use validation functions for robust applications
6. **Test your menus** - Run through all options to ensure handlers work

## Contributing

Contributions are welcome! Please ensure:
- All tests pass: `./tests/run_tests.sh`
- New functions include tests
- Code follows existing style
- Documentation is updated

## License

SPDX-License-Identifier: Apache-2.0

Copyright 2024 3mdeb <contact@3mdeb.com>

## Support

For issues and questions:
- GitHub Issues: https://github.com/Dasharo/dasharo-issues
- Documentation: https://docs.dasharo.com
