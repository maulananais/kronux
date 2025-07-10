#!/bin/bash

# KRONUX - Kernel Runtime Operations for Linux
# Author: Maulana Nais
# Description: Modular system for post-installation setup on various Linux distributions

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all modules
source "$SCRIPT_DIR/config/config.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/modules/package_manager.sh"
source "$SCRIPT_DIR/modules/actions.sh"
source "$SCRIPT_DIR/modules/uninstaller.sh"
source "$SCRIPT_DIR/modules/menus.sh"

# Loading screen with animation
show_loading_screen() {
    clear
    local spinner_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local loading_text="Loading KRONUX..."
    
    # Show loading animation
    for i in {1..20}; do
        local spinner_idx=$((i % ${#spinner_chars[@]}))
        echo -ne "\r${spinner_chars[$spinner_idx]} $loading_text"
        sleep 0.1
    done
    echo
    
    # Display KRONUX ASCII logo
    echo -e "${CYAN}${BOLD}"
    echo "  ██╗  ██╗██████╗  ██████╗ ███╗   ██╗██╗   ██╗██╗  ██╗"
    echo "  ██║ ██╔╝██╔══██╗██╔═══██╗████╗  ██║██║   ██║╚██╗██╔╝"
    echo "  █████╔╝ ██████╔╝██║   ██║██╔██╗ ██║██║   ██║ ╚███╔╝ "
    echo "  ██╔═██╗ ██╔══██╗██║   ██║██║╚██╗██║██║   ██║ ██╔██╗ "
    echo "  ██║  ██╗██║  ██║╚██████╔╝██║ ╚████║╚██████╔╝██╔╝ ██╗"
    echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    
    sleep 2
}

# Main function
main() {
    # Show loading screen
    show_loading_screen
    
    # Initialize logging
    init_log
    
    # Check for sudo access
    clear
    echo_info "KRONUX requires sudo access for package management operations."
    echo_warning "You will be prompted for your password when needed."
    echo_info "Testing sudo access..."
    
    if ! sudo -v; then
        echo_error "Sudo access is required to run KRONUX."
        echo_error "Please run this script with appropriate privileges."
        exit 1
    fi
    
    echo_success "Sudo access confirmed."
    sleep 1
    
    # Start with package manager selection
    push_nav select_package_manager
    select_package_manager
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
