#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Verification script for bash-ui-lib
# Checks that all components are present and can be loaded

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NORMAL='\033[0m'

ERRORS=0

echo "bash-ui-lib Verification Script"
echo "================================"
echo

# Check directory structure
echo -n "Checking directory structure... "
for dir in lib tests examples docs; do
  if [[ ! -d "$dir" ]]; then
    echo -e "${RED}FAIL${NORMAL}"
    echo "  Missing directory: $dir"
    ((ERRORS++))
  fi
done
echo -e "${GREEN}OK${NORMAL}"

# Check library files
echo -n "Checking library files... "
REQUIRED_LIBS=(
  "lib/ui-colors.sh"
  "lib/ui-utils.sh"
  "lib/ui-render.sh"
  "lib/ui-core.sh"
  "lib/dts-ui-adapter.sh"
)

for lib in "${REQUIRED_LIBS[@]}"; do
  if [[ ! -f "$lib" ]]; then
    echo -e "${RED}FAIL${NORMAL}"
    echo "  Missing file: $lib"
    ((ERRORS++))
  fi
done
echo -e "${GREEN}OK${NORMAL}"

# Check if libraries can be sourced
echo -n "Checking library loading... "
LOAD_ERRORS=0

if ! bash -c "source lib/ui-colors.sh" 2>/dev/null; then
  echo -e "${RED}FAIL${NORMAL}"
  echo "  Failed to load ui-colors.sh"
  ((ERRORS++))
  ((LOAD_ERRORS++))
fi

if ! bash -c "source lib/ui-utils.sh" 2>/dev/null; then
  echo -e "${RED}FAIL${NORMAL}"
  echo "  Failed to load ui-utils.sh"
  ((ERRORS++))
  ((LOAD_ERRORS++))
fi

if ! bash -c "source lib/ui-render.sh" 2>/dev/null; then
  echo -e "${RED}FAIL${NORMAL}"
  echo "  Failed to load ui-render.sh"
  ((ERRORS++))
  ((LOAD_ERRORS++))
fi

if ! bash -c "source lib/ui-core.sh" 2>/dev/null; then
  echo -e "${RED}FAIL${NORMAL}"
  echo "  Failed to load ui-core.sh"
  ((ERRORS++))
  ((LOAD_ERRORS++))
fi

if [[ $LOAD_ERRORS -eq 0 ]]; then
  echo -e "${GREEN}OK${NORMAL}"
fi

# Check test files
echo -n "Checking test files... "
REQUIRED_TESTS=(
  "tests/test_ui_colors.bats"
  "tests/test_ui_utils.bats"
  "tests/test_ui_render.bats"
  "tests/test_ui_core.bats"
  "tests/run_tests.sh"
)

for test in "${REQUIRED_TESTS[@]}"; do
  if [[ ! -f "$test" ]]; then
    echo -e "${RED}FAIL${NORMAL}"
    echo "  Missing file: $test"
    ((ERRORS++))
  fi
done
echo -e "${GREEN}OK${NORMAL}"

# Check examples
echo -n "Checking example files... "
REQUIRED_EXAMPLES=(
  "examples/simple-menu.sh"
  "examples/advanced-menu.sh"
  "examples/dts-integration-example.sh"
)

for example in "${REQUIRED_EXAMPLES[@]}"; do
  if [[ ! -f "$example" ]]; then
    echo -e "${RED}FAIL${NORMAL}"
    echo "  Missing file: $example"
    ((ERRORS++))
  elif [[ ! -x "$example" ]]; then
    echo -e "${YELLOW}WARN${NORMAL}"
    echo "  File not executable: $example"
  fi
done
echo -e "${GREEN}OK${NORMAL}"

# Check documentation
echo -n "Checking documentation... "
REQUIRED_DOCS=(
  "README.md"
  "LICENSE"
  "SUMMARY.md"
  "docs/QUICKSTART.md"
  "docs/TESTING.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
  if [[ ! -f "$doc" ]]; then
    echo -e "${RED}FAIL${NORMAL}"
    echo "  Missing file: $doc"
    ((ERRORS++))
  fi
done
echo -e "${GREEN}OK${NORMAL}"

# Check key functions exist (by loading library in subshell)
echo -n "Checking API functions... "
FUNC_CHECK=$(bash -c '
source lib/ui-core.sh 2>/dev/null
REQUIRED_FUNCTIONS=(
  "ui_add_menu_item"
  "ui_add_footer_action"
  "ui_main_loop"
  "ui_echo_green"
  "ui_ask_yes_no"
  "ui_progress_bar"
  "ui_validate_not_empty"
)
missing=0
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! type -t "$func" &>/dev/null; then
    echo "$func"
    ((missing++))
  fi
done
exit $missing
' 2>/dev/null)

if [[ $? -ne 0 ]]; then
  echo -e "${RED}FAIL${NORMAL}"
  echo "  Missing functions: $FUNC_CHECK"
  ((ERRORS++))
else
  echo -e "${GREEN}OK${NORMAL}"
fi

# Summary
echo
echo "Verification Summary"
echo "===================="

if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}All checks passed!${NORMAL}"
  echo
  echo "Next steps:"
  echo "  1. Run tests: cd tests && ./run_tests.sh"
  echo "  2. Try examples: ./examples/simple-menu.sh"
  echo "  3. Read documentation: cat README.md"
  echo
  exit 0
else
  echo -e "${RED}Found $ERRORS error(s)${NORMAL}"
  echo
  echo "Please fix the errors above and try again."
  exit 1
fi
