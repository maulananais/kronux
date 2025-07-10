#!/bin/bash

# KRONUX Configuration
# Author: Maulana Nais
# Description: Configuration file for KRONUX

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Package manager configuration
PACKAGE_MANAGER=""

# Log file paths
LOG_FILE="$SCRIPT_DIR/logs/install-log.txt"
UNINSTALL_LOG_FILE="$SCRIPT_DIR/logs/uninstall-log.txt"

# Global arrays for selections
SELECTED_ITEMS=()
UNINSTALL_SELECTED_ITEMS=()

# Navigation and state
CURRENT_CATEGORY=""
NAV_STACK=()

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# KRONUX version
KRONUX_VERSION="1.0"
