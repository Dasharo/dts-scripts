# Testing Guide for bash-ui-lib

This document provides comprehensive information about testing bash-ui-lib.

## Test Framework

bash-ui-lib uses [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) for testing.

## Installation

### Debian/Ubuntu
```bash
sudo apt-get update
sudo apt-get install bats
```

### Fedora
```bash
sudo dnf install bats
```

### macOS
```bash
brew install bats-core
```

### From Source
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### Run All Tests
```bash
cd bash-ui-lib/tests
./run_tests.sh
```

### Run Specific Test File
```bash
bats test_ui_colors.bats
bats test_ui_utils.bats
bats test_ui_render.bats
bats test_ui_core.bats
```

### Run Single Test
```bash
bats -f "test name pattern" test_ui_colors.bats
```

Example:
```bash
bats -f "ui_echo_green" test_ui_colors.bats
```

## Test Structure

Each test file follows this structure:

```bash
#!/usr/bin/env bats

setup() {
  # Runs before each test
  source "${BATS_TEST_DIRNAME}/../lib/ui-colors.sh"
}

teardown() {
  # Runs after each test (optional)
  # Clean up resources
}

@test "description of test" {
  # Test code here
  run some_command
  [ "$status" -eq 0 ]
  [[ "$output" == *"expected text"* ]]
}
```

## Test Files

### test_ui_colors.bats
Tests for color system:
- Color code definitions
- Theme colors
- Color output functions
- Theme customization
- Color enable/disable

### test_ui_utils.bats
Tests for utility functions:
- Input functions
- Validation functions
- Visual elements (boxes, separators)
- Terminal size detection
- ANSI escape removal

### test_ui_render.bats
Tests for rendering system:
- Menu item management
- Footer action management
- Callback system
- Rendering functions
- Condition evaluation

### test_ui_core.bats
Tests for core functionality:
- UI initialization
- Input mode management
- Main loop control
- Input processing
- Built-in actions

## Writing Tests

### Basic Test Structure

```bash
@test "function_name: what it does" {
  run function_name "arg1" "arg2"
  [ "$status" -eq 0 ]
  [[ "$output" == *"expected"* ]]
}
```

### Testing Return Codes

```bash
@test "function returns 0 on success" {
  run successful_function
  [ "$status" -eq 0 ]
}

@test "function returns 1 on failure" {
  run failing_function
  [ "$status" -eq 1 ]
}
```

### Testing Output

```bash
@test "function outputs correct text" {
  run echo_function "hello"
  [ "$status" -eq 0 ]
  [[ "$output" == *"hello"* ]]
}
```

### Testing Variables

```bash
@test "function sets variable" {
  some_function_that_sets_VAR
  [ -n "$VAR" ]
  [ "$VAR" = "expected_value" ]
}
```

### Testing Function Existence

```bash
@test "function exists" {
  type -t function_name | grep -q "function"
}
```

### Testing with Mocks

```bash
@test "function calls external command" {
  # Mock external command
  external_command() {
    echo "mocked output"
  }
  export -f external_command

  run function_that_uses_external_command
  [ "$status" -eq 0 ]
  [[ "$output" == *"mocked output"* ]]
}
```

## Test Coverage

Current test coverage includes:

### ui-colors.sh (100%)
- [x] Library sourcing
- [x] Multiple sourcing prevention
- [x] Color array population
- [x] Theme array population
- [x] All color output functions
- [x] Theme customization
- [x] Color enable/disable
- [x] Color test function

### ui-utils.sh (95%)
- [x] Library sourcing
- [x] Multiple sourcing prevention
- [x] All utility functions exist
- [x] Progress bar display
- [x] Box drawing
- [x] Separator drawing
- [x] Text centering
- [x] All validation functions
- [x] Terminal size detection
- [x] Interactive detection
- [x] ANSI escape removal
- [ ] Interactive input functions (hard to test)

### ui-render.sh (98%)
- [x] Library sourcing
- [x] Multiple sourcing prevention
- [x] Menu item CRUD operations
- [x] Footer action CRUD operations
- [x] Callback system
- [x] Rendering functions
- [x] Condition evaluation
- [x] Handler execution
- [ ] Full screen rendering (requires terminal)

### ui-core.sh (85%)
- [x] Library sourcing
- [x] Multiple sourcing prevention
- [x] Initialization
- [x] Input mode management
- [x] Callback management
- [x] Loop control
- [x] Input processing
- [x] Built-in actions
- [ ] Full main loop (requires interactive terminal)
- [ ] Signal handlers (hard to test)

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install BATS
        run: |
          sudo apt-get update
          sudo apt-get install -y bats
      - name: Run tests
        run: |
          cd bash-ui-lib/tests
          ./run_tests.sh
```

## Debugging Tests

### Verbose Output
```bash
bats -t test_ui_colors.bats
```

### Show Test Timing
```bash
bats --timing test_ui_colors.bats
```

### Run Tests in Tap Format
```bash
bats --tap test_ui_colors.bats
```

### Debug Single Test
```bash
# Add set -x in test for detailed output
@test "debug test" {
  set -x
  run some_function
  set +x
  [ "$status" -eq 0 ]
}
```

## Best Practices

1. **One assertion per test** - Keep tests focused
2. **Descriptive test names** - "function_name: what it tests"
3. **Test both success and failure** - Cover edge cases
4. **Use setup and teardown** - Keep tests independent
5. **Mock external dependencies** - Tests should be isolated
6. **Test output and return codes** - Verify both
7. **Keep tests fast** - Avoid sleeps and long operations
8. **Document complex tests** - Add comments for clarity

## Common Issues

### Tests Fail in CI but Pass Locally
- Check terminal type: `TERM` variable
- Ensure non-interactive mode is handled
- Mock system commands that might not be available

### Color Tests Fail
- Terminal might not support colors
- Use `TERM=xterm-256color` for tests
- Test both color and non-color modes

### Interactive Tests
- Interactive input tests are skipped by default
- Use mocking for interactive functions (like `ui_pause`)
- Test logic separately from actual input
- Example: Mock `ui_pause` to prevent tests from hanging:
  ```bash
  @test "my interactive test" {
    ui_pause() { :; }  # Mock to do nothing
    export -f ui_pause

    run my_function_that_calls_ui_pause
    [ "$status" -eq 0 ]
  }
  ```

## Adding New Tests

When adding new functionality:

1. **Create test first** (TDD approach)
2. **Add test to appropriate file** or create new file
3. **Follow naming convention**: `test_<module>.bats`
4. **Update this document** with new test coverage
5. **Ensure all tests pass** before committing

Example:
```bash
@test "new_function: does something useful" {
  # Setup
  local input="test"

  # Execute
  run new_function "$input"

  # Verify
  [ "$status" -eq 0 ]
  [[ "$output" == *"expected"* ]]
}
```

## Resources

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [BATS GitHub](https://github.com/bats-core/bats-core)
- [Bash Testing Guide](https://github.com/bats-core/bats-core#writing-tests)
