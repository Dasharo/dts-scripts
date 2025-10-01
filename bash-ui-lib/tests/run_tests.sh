#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

# Test runner for bash-ui-lib
# Requires bats-core to be installed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NORMAL='\033[0m'

echo "bash-ui-lib Test Runner"
echo "======================="
echo

# Check if bats is installed
if ! command -v bats &>/dev/null; then
  echo -e "${RED}Error: bats is not installed${NORMAL}"
  echo
  echo "Please install bats-core:"
  echo "  Debian/Ubuntu: sudo apt-get install bats"
  echo "  Fedora:        sudo dnf install bats"
  echo "  macOS:         brew install bats-core"
  echo "  From source:   git clone https://github.com/bats-core/bats-core.git && cd bats-core && sudo ./install.sh /usr/local"
  exit 1
fi

# Run tests
echo "Running tests..."
echo

if bats "$SCRIPT_DIR"/*.bats; then
  echo
  echo -e "${GREEN}All tests passed!${NORMAL}"
  exit 0
else
  echo
  echo -e "${RED}Some tests failed!${NORMAL}"
  exit 1
fi
