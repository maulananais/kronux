#!/bin/bash

# KRONUX Utilities
# Author: Maulana Nais
# Description: Utility functions for KRONUX

# Source configuration
source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"

# Display functions - Clean minimal headers
show_ascii_logo() {
    # This function is now only used during loading screen
    # All other screens should be clean without logos
    return 0
}

show_header() {
    local title="$1"
    echo -e "${BOLD}${title}${NC}"
    echo
}

show_footer() {
    echo
}

# Spinner animation for operations
show_spinner() {
    local pid=$1
    local message="$2"
    local spinner_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        local spinner_idx=$((i % ${#spinner_chars[@]}))
        echo -ne "\r${spinner_chars[$spinner_idx]} $message"
        sleep 0.1
        ((i++))
    done
    echo -ne "\r"
}

# Enhanced confirmation with package list
confirm_installation() {
    local action="$1"
    shift
    local packages=("$@")
    
    echo_info "The following packages will be ${action}ed:"
    for pkg in "${packages[@]}"; do
        echo -e "  ${CYAN}•${NC} $pkg"
    done
    echo
    echo -n "Do you want to continue? [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Run command with spinner animation
run_with_spinner() {
    local message="$1"
    shift
    local command=("$@")
    
    # Run command in background
    "${command[@]}" >/dev/null 2>&1 &
    local pid=$!
    
    # Show spinner while command runs
    show_spinner $pid "$message"
    
    # Wait for command to complete and get exit code
    wait $pid
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo_success "$message - Complete"
    else
        echo_error "$message - Failed"
    fi
    
    return $exit_code
}

# Navigation functions
push_nav() { NAV_STACK+=("$1"); }
pop_nav() { 
    if [[ ${#NAV_STACK[@]} -gt 1 ]]; then
        unset NAV_STACK[-1]
    fi
}

# Exit function
exit_toolkit() {
    clear
    echo_info "Thanks for using KRONUX!"
    echo_info "Goodbye!"
    exit 0
}

# Initialize logging
init_log() {
    # Initialize install log
    mkdir -p "$(dirname "$LOG_FILE")"
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "=== KRONUX: Kernel Runtime Operations for Linux - Install Log ===" > "$LOG_FILE"
        echo "Started: $(date)" >> "$LOG_FILE"
        echo "=========================================" >> "$LOG_FILE"
    fi
    
    # Initialize uninstall log
    mkdir -p "$(dirname "$UNINSTALL_LOG_FILE")"
    if [[ ! -f "$UNINSTALL_LOG_FILE" ]]; then
        echo "=== KRONUX: Kernel Runtime Operations for Linux - Uninstall Log ===" > "$UNINSTALL_LOG_FILE"
        echo "Started: $(date)" >> "$UNINSTALL_LOG_FILE"
        echo "=========================================" >> "$UNINSTALL_LOG_FILE"
    fi
}

# Echo functions with colors
echo_success() { echo -e "${GREEN}${BOLD}✓${NC} $1"; }
echo_error() { echo -e "${RED}${BOLD}✗${NC} $1"; }
echo_warning() { echo -e "${YELLOW}${BOLD}⚠${NC} $1"; }
echo_info() { echo -e "${BLUE}${BOLD}ℹ${NC} $1"; }
echo_progress() { echo -e "${PURPLE}${BOLD}→${NC} $1"; }

echo_menu_item() {
    local number="$1"; local description="$2"; local status="$3"
    if [[ -n "$status" ]]; then
        echo -e "${CYAN}${BOLD}[$number]${NC} $description ${status}"
    else
        echo -e "${CYAN}${BOLD}[$number]${NC} $description"
    fi
}

# Selection utility functions
is_selected() {
    local item="$1"
    for selected in "${SELECTED_ITEMS[@]}"; do
        [[ "$selected" == "$item" ]] && return 0
    done
    return 1
}

toggle_selection() {
    local item="$1"; local found=false; local temp_array=()
    for selected in "${SELECTED_ITEMS[@]}"; do
        if [[ "$selected" == "$item" ]]; then found=true; else temp_array+=("$selected"); fi
    done
    if [[ "$found" == false ]]; then SELECTED_ITEMS+=("$item"); else SELECTED_ITEMS=("${temp_array[@]}"); fi
}

show_selected_items() {
    if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
        echo_info "Currently selected (${#SELECTED_ITEMS[@]}):"
        for item in "${SELECTED_ITEMS[@]}"; do echo -e "  ${GREEN}•${NC} $item"; done
    else
        echo_info "No items selected"
    fi
}

# User interaction functions
confirm_action() {
    local action="$1"
    echo -e "${YELLOW}${BOLD}Are you sure you want to $action? [y/N]:${NC} "
    read -r response
    case "$response" in [yY][eE][sS]|[yY]) return 0 ;; *) return 1 ;; esac
}

pause_for_user() { echo -e "${CYAN}Press Enter to continue...${NC}"; read -r; }

# System utility functions
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Package status checking functions
check_package_installed() {
    local pkg_name="$1"
    case "$PACKAGE_MANAGER" in
        "apt") 
            dpkg -l "$pkg_name" &>/dev/null || apt list --installed "$pkg_name" 2>/dev/null | grep -q "installed"
            ;;
        "dnf"|"yum") 
            rpm -q "$pkg_name" &>/dev/null || dnf list installed "$pkg_name" &>/dev/null
            ;;
        "pacman"|"yay") 
            pacman -Q "$pkg_name" &>/dev/null
            ;;
        "zypper") 
            zypper search -i "$pkg_name" &>/dev/null | grep -q "^i"
            ;;
        *) return 1 ;;
    esac
}

check_service_status() {
    local service_name="$1"
    systemctl is-enabled "$service_name" &>/dev/null
}

# Check if package needs special installation
needs_special_installation() {
    local item="$1"
    
    case "$item" in
        "Google Chrome"|"Microsoft Edge"|"Brave Browser"|"Visual Studio Code"|"Discord"|"Zoom"|"Slack"|"Spotify"|"Steam"|"Docker"|"Flatpak"|"Snap")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Enhanced package installation with special handling
install_package_with_check() {
    local item="$1"
    local pkg_name="$2"
    
    # Check if package is already installed
    if check_package_installed "$pkg_name"; then
        echo_warning "$item is already installed"
        log_action "ALREADY_INSTALLED" "$pkg_name"
        return 0
    fi
    
    # Check if special installation is needed
    if needs_special_installation "$item"; then
        echo_info "$item requires special installation method"
        if install_special_package "$item" "$pkg_name"; then
            return 0
        else
            echo_warning "Special installation failed, attempting standard installation..."
        fi
    fi
    
    # Standard installation
    echo_progress "Installing $item..."
    if install_package "$pkg_name"; then
        echo_success "Successfully installed $item"
        log_action "INSTALL_SUCCESS" "$pkg_name"
        return 0
    else
        echo_error "Failed to install $item"
        log_action "INSTALL_FAILED" "$pkg_name"
        return 1
    fi
}

# Standard package installation function
install_package() {
    local pkg_name="$1"
    
    case "$PACKAGE_MANAGER" in
        "apt") 
            sudo apt install -y $pkg_name
            return $?
            ;;
        "dnf") 
            sudo dnf install -y $pkg_name
            return $?
            ;;
        "yum") 
            sudo yum install -y $pkg_name
            return $?
            ;;
        "pacman"|"yay") 
            if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
                sudo pacman -S --noconfirm $pkg_name
            else
                yay -S --noconfirm $pkg_name
            fi
            return $?
            ;;
        "zypper") 
            sudo zypper install -y $pkg_name
            return $?
            ;;
        *) 
            echo_error "Unknown package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

# Enhanced package uninstallation with pre-checks
uninstall_package_with_check() {
    local item="$1"
    local pkg_name="$2"
    
    # Check if package is installed
    if ! check_package_installed "$pkg_name"; then
        echo_warning "$item is not installed"
        log_action "NOT_INSTALLED" "$pkg_name"
        return 0
    fi
    
    echo_progress "Uninstalling $item ($pkg_name)..."
    
    case "$PACKAGE_MANAGER" in
        "apt") 
            if sudo apt remove -y $pkg_name; then
                echo_success "Successfully uninstalled $item"
                log_action "UNINSTALL_SUCCESS" "$pkg_name"
                return 0
            else
                echo_error "Failed to uninstall $item"
                log_action "UNINSTALL_FAILED" "$pkg_name"
                return 1
            fi
            ;;
        "dnf") 
            if sudo dnf remove -y $pkg_name; then
                echo_success "Successfully uninstalled $item"
                log_action "UNINSTALL_SUCCESS" "$pkg_name"
                return 0
            else
                echo_error "Failed to uninstall $item"
                log_action "UNINSTALL_FAILED" "$pkg_name"
                return 1
            fi
            ;;
        "yum") 
            if sudo yum remove -y $pkg_name; then
                echo_success "Successfully uninstalled $item"
                log_action "UNINSTALL_SUCCESS" "$pkg_name"
                return 0
            else
                echo_error "Failed to uninstall $item"
                log_action "UNINSTALL_FAILED" "$pkg_name"
                return 1
            fi
            ;;
        "pacman"|"yay") 
            if yay -R --noconfirm $pkg_name; then
                echo_success "Successfully uninstalled $item"
                log_action "UNINSTALL_SUCCESS" "$pkg_name"
                return 0
            else
                echo_error "Failed to uninstall $item"
                log_action "UNINSTALL_FAILED" "$pkg_name"
                return 1
            fi
            ;;
        "zypper") 
            if sudo zypper remove -y $pkg_name; then
                echo_success "Successfully uninstalled $item"
                log_action "UNINSTALL_SUCCESS" "$pkg_name"
                return 0
            else
                echo_error "Failed to uninstall $item"
                log_action "UNINSTALL_FAILED" "$pkg_name"
                return 1
            fi
            ;;
        *) 
            echo_error "Unknown package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

# Special package installation cases
install_special_package() {
    local item="$1"
    local pkg_name="$2"
    
    echo_progress "Installing $item (special package)..."
    
    case "$item" in
        "Google Chrome")
            install_google_chrome
            ;;
        "Microsoft Edge")
            install_microsoft_edge
            ;;
        "Brave Browser")
            install_brave_browser
            ;;
        "Visual Studio Code")
            install_vscode
            ;;
        "Discord")
            install_discord
            ;;
        "Zoom")
            install_zoom
            ;;
        "Slack")
            install_slack
            ;;
        "Spotify")
            install_spotify
            ;;
        "Steam")
            install_steam
            ;;
        "Docker")
            install_docker
            ;;
        "Docker Compose")
            install_docker_compose
            ;;
        "Flatpak")
            install_flatpak
            ;;
        "Snap")
            install_snap
            ;;
        *)
            echo_warning "No special installation method for $item"
            return 1
            ;;
    esac
}

# Logging functions
log_action() {
    local action_type="$1"
    local package_name="$2"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case "$action_type" in
        "INSTALL_SUCCESS")
            echo "$timestamp: [INSTALL_SUCCESS] $package_name" >> "$LOG_FILE"
            ;;
        "INSTALL_FAILED")
            echo "$timestamp: [INSTALL_FAILED] $package_name" >> "$LOG_FILE"
            ;;
        "UNINSTALL_SUCCESS")
            mkdir -p "$(dirname "$UNINSTALL_LOG_FILE")"
            echo "$timestamp: [UNINSTALL_SUCCESS] $package_name" >> "$UNINSTALL_LOG_FILE"
            ;;
        "UNINSTALL_FAILED")
            mkdir -p "$(dirname "$UNINSTALL_LOG_FILE")"
            echo "$timestamp: [UNINSTALL_FAILED] $package_name" >> "$UNINSTALL_LOG_FILE"
            ;;
        "ALREADY_INSTALLED")
            echo "$timestamp: [ALREADY_INSTALLED] $package_name" >> "$LOG_FILE"
            ;;
        "NOT_INSTALLED")
            echo "$timestamp: [NOT_INSTALLED] $package_name" >> "$UNINSTALL_LOG_FILE"
            ;;
        *)
            echo "$timestamp - UNKNOWN ACTION: $action_type for $package_name" >> "$LOG_FILE"
            ;;
    esac
}

# Special package installation functions

# Google Chrome installation
install_google_chrome() {
    echo_progress "Installing Google Chrome..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            # Add Google Chrome repository
            if ! command -v curl &> /dev/null; then
                sudo apt update && sudo apt install -y curl
            fi
            
            curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
            
            sudo apt update
            if sudo apt install -y google-chrome-stable; then
                echo_success "Successfully installed Google Chrome"
                log_action "INSTALL_SUCCESS" "google-chrome-stable"
                return 0
            fi
            ;;
        "dnf"|"yum")
            # Add Google Chrome repository
            sudo cat > /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=Google Chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
            
            if sudo $PACKAGE_MANAGER install -y google-chrome-stable; then
                echo_success "Successfully installed Google Chrome"
                log_action "INSTALL_SUCCESS" "google-chrome-stable"
                return 0
            fi
            ;;
        "yay")
            if yay -S --noconfirm google-chrome; then
                echo_success "Successfully installed Google Chrome"
                log_action "INSTALL_SUCCESS" "google-chrome"
                return 0
            fi
            ;;
        "zypper")
            # Add Google Chrome repository
            sudo zypper ar -f http://dl.google.com/linux/chrome/rpm/stable/x86_64 google-chrome
            sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub
            
            if sudo zypper install -y google-chrome-stable; then
                echo_success "Successfully installed Google Chrome"
                log_action "INSTALL_SUCCESS" "google-chrome-stable"
                return 0
            fi
            ;;
    esac
    
    echo_error "Failed to install Google Chrome"
    log_action "INSTALL_FAILED" "google-chrome-stable"
    return 1
}

# Microsoft Edge installation
install_microsoft_edge() {
    echo_progress "Installing Microsoft Edge..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            # Add Microsoft Edge repository
            if ! command -v curl &> /dev/null; then
                sudo apt update && sudo apt install -y curl
            fi
            
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge-keyring.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
            
            sudo apt update
            if sudo apt install -y microsoft-edge-stable; then
                echo_success "Successfully installed Microsoft Edge"
                log_action "INSTALL_SUCCESS" "microsoft-edge-stable"
                return 0
            fi
            ;;
        "dnf"|"yum")
            # Add Microsoft repository
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo cat > /etc/yum.repos.d/microsoft-edge.repo << 'EOF'
[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
            
            if sudo $PACKAGE_MANAGER install -y microsoft-edge-stable; then
                echo_success "Successfully installed Microsoft Edge"
                log_action "INSTALL_SUCCESS" "microsoft-edge-stable"
                return 0
            fi
            ;;
        "yay")
            if yay -S --noconfirm microsoft-edge-stable-bin; then
                echo_success "Successfully installed Microsoft Edge"
                log_action "INSTALL_SUCCESS" "microsoft-edge-stable-bin"
                return 0
            fi
            ;;
        "zypper")
            # Add Microsoft repository
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo zypper ar -f https://packages.microsoft.com/yumrepos/edge microsoft-edge
            
            if sudo zypper install -y microsoft-edge-stable; then
                echo_success "Successfully installed Microsoft Edge"
                log_action "INSTALL_SUCCESS" "microsoft-edge-stable"
                return 0
            fi
            ;;
    esac
    
    echo_error "Failed to install Microsoft Edge"
    log_action "INSTALL_FAILED" "microsoft-edge-stable"
    return 1
}

# Brave Browser installation
install_brave_browser() {
    echo_progress "Installing Brave Browser..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            # Add Brave repository
            if ! command -v curl &> /dev/null; then
                sudo apt update && sudo apt install -y curl
            fi
            
            curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/brave-browser-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
            
            sudo apt update
            if sudo apt install -y brave-browser; then
                echo_success "Successfully installed Brave Browser"
                log_action "INSTALL_SUCCESS" "brave-browser"
                return 0
            fi
            ;;
        "dnf"|"yum")
            # Add Brave repository
            sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            sudo cat > /etc/yum.repos.d/brave-browser.repo << 'EOF'
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF
            
            if sudo $PACKAGE_MANAGER install -y brave-browser; then
                echo_success "Successfully installed Brave Browser"
                log_action "INSTALL_SUCCESS" "brave-browser"
                return 0
            fi
            ;;
        "yay")
            if yay -S --noconfirm brave-bin; then
                echo_success "Successfully installed Brave Browser"
                log_action "INSTALL_SUCCESS" "brave-bin"
                return 0
            fi
            ;;
        "zypper")
            # Add Brave repository
            sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            sudo zypper ar -f https://brave-browser-rpm-release.s3.brave.com/x86_64/ brave-browser
            
            if sudo zypper install -y brave-browser; then
                echo_success "Successfully installed Brave Browser"
                log_action "INSTALL_SUCCESS" "brave-browser"
                return 0
            fi
            ;;
    esac
    
    echo_error "Failed to install Brave Browser"
    log_action "INSTALL_FAILED" "brave-browser"
    return 1
}

# Visual Studio Code installation
install_vscode() {
    echo_progress "Installing Visual Studio Code..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            # Add VS Code repository
            if ! command -v curl &> /dev/null; then
                sudo apt update && sudo apt install -y curl
            fi
            
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages-microsoft-com.gpg
            echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages-microsoft-com.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
            
            sudo apt update
            if sudo apt install -y code; then
                echo_success "Successfully installed Visual Studio Code"
                log_action "INSTALL_SUCCESS" "code"
                return 0
            fi
            ;;
        "dnf"|"yum")
            # Add VS Code repository
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo cat > /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
            
            if sudo $PACKAGE_MANAGER install -y code; then
                echo_success "Successfully installed Visual Studio Code"
                log_action "INSTALL_SUCCESS" "code"
                return 0
            fi
            ;;
        "yay")
            if yay -S --noconfirm visual-studio-code-bin; then
                echo_success "Successfully installed Visual Studio Code"
                log_action "INSTALL_SUCCESS" "visual-studio-code-bin"
                return 0
            fi
            ;;
        "zypper")
            # Add VS Code repository
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo zypper ar -f https://packages.microsoft.com/yumrepos/vscode vscode
            
            if sudo zypper install -y code; then
                echo_success "Successfully installed Visual Studio Code"
                log_action "INSTALL_SUCCESS" "code"
                return 0
            fi
            ;;
    esac
    
    echo_error "Failed to install Visual Studio Code"
    log_action "INSTALL_FAILED" "code"
    return 1
}

# Discord installation
install_discord() {
    echo_progress "Installing Discord..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            # Download and install Discord deb package
            local temp_dir=$(mktemp -d)
            cd "$temp_dir"
            
            if wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"; then
                if sudo dpkg -i discord.deb; then
                    echo_success "Successfully installed Discord"
                    log_action "INSTALL_SUCCESS" "discord"
                    rm -rf "$temp_dir"
                    return 0
                else
                    # Fix dependencies if needed
                    sudo apt -f install -y
                    rm -rf "$temp_dir"
                    return 1
                fi
            fi
            ;;
        "dnf"|"yum")
            # Download and install Discord rpm package
            local temp_dir=$(mktemp -d)
            cd "$temp_dir"
            
            if wget -O discord.rpm "https://discord.com/api/download?platform=linux&format=rpm"; then
                if sudo $PACKAGE_MANAGER install -y discord.rpm; then
                    echo_success "Successfully installed Discord"
                    log_action "INSTALL_SUCCESS" "discord"
                    rm -rf "$temp_dir"
                    return 0
                fi
            fi
            ;;
        "yay")
            if yay -S --noconfirm discord; then
                echo_success "Successfully installed Discord"
                log_action "INSTALL_SUCCESS" "discord"
                return 0
            fi
            ;;
        "zypper")
            # Download and install Discord rpm package
            local temp_dir=$(mktemp -d)
            cd "$temp_dir"
            
            if wget -O discord.rpm "https://discord.com/api/download?platform=linux&format=rpm"; then
                if sudo zypper install -y discord.rpm; then
                    echo_success "Successfully installed Discord"
                    log_action "INSTALL_SUCCESS" "discord"
                    rm -rf "$temp_dir"
                    return 0
                fi
            fi
            ;;
    esac
    
    echo_error "Failed to install Discord"
    log_action "INSTALL_FAILED" "discord"
    return 1
}

# Docker installation
install_docker() {
    echo_progress "Installing Docker..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            # Add Docker repository
            if ! command -v curl &> /dev/null; then
                sudo apt update && sudo apt install -y curl
            fi
            
            # Remove old versions
            sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Install prerequisites
            sudo apt update
            sudo apt install -y ca-certificates curl gnupg lsb-release
            
            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt update
            if sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
                # Add user to docker group
                sudo usermod -aG docker $USER
                sudo systemctl enable docker
                sudo systemctl start docker
                echo_success "Successfully installed Docker"
                echo_info "Please log out and log back in for Docker group membership to take effect"
                log_action "INSTALL_SUCCESS" "docker-ce"
                return 0
            fi
            ;;
        "dnf"|"yum")
            # Add Docker repository
            sudo $PACKAGE_MANAGER install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            if sudo $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
                # Add user to docker group
                sudo usermod -aG docker $USER
                sudo systemctl enable docker
                sudo systemctl start docker
                echo_success "Successfully installed Docker"
                echo_info "Please log out and log back in for Docker group membership to take effect"
                log_action "INSTALL_SUCCESS" "docker-ce"
                return 0
            fi
            ;;
        "yay")
            if yay -S --noconfirm docker docker-compose; then
                # Add user to docker group
                sudo usermod -aG docker $USER
                sudo systemctl enable docker
                sudo systemctl start docker
                echo_success "Successfully installed Docker"
                echo_info "Please log out and log back in for Docker group membership to take effect"
                log_action "INSTALL_SUCCESS" "docker"
                return 0
            fi
            ;;
        "zypper")
            if sudo zypper install -y docker docker-compose; then
                # Add user to docker group
                sudo usermod -aG docker $USER
                sudo systemctl enable docker
                sudo systemctl start docker
                echo_success "Successfully installed Docker"
                echo_info "Please log out and log back in for Docker group membership to take effect"
                log_action "INSTALL_SUCCESS" "docker"
                return 0
            fi
            ;;
    esac
    
    echo_error "Failed to install Docker"
    log_action "INSTALL_FAILED" "docker"
    return 1
}

# Additional special installation functions can be added here...

# Generic function to install via direct download
install_via_download() {
    local app_name="$1"
    local download_url="$2"
    local filename="$3"
    local install_command="$4"
    
    echo_progress "Installing $app_name via direct download..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    if wget -O "$filename" "$download_url"; then
        if eval "$install_command"; then
            echo_success "Successfully installed $app_name"
            log_action "INSTALL_SUCCESS" "$app_name"
            rm -rf "$temp_dir"
            return 0
        fi
    fi
    
    echo_error "Failed to install $app_name"
    log_action "INSTALL_FAILED" "$app_name"
    rm -rf "$temp_dir"
    return 1
}

# Flatpak installation
install_flatpak() {
    echo_progress "Installing Flatpak..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            if sudo apt install -y flatpak; then
                # Add Flathub repository
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                echo_success "Successfully installed Flatpak"
                log_action "INSTALL_SUCCESS" "flatpak"
                return 0
            fi
            ;;
        "dnf"|"yum")
            if sudo $PACKAGE_MANAGER install -y flatpak; then
                # Add Flathub repository
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                echo_success "Successfully installed Flatpak"
                log_action "INSTALL_SUCCESS" "flatpak"
                return 0
            fi
            ;;
        "yay")
            if yay -S --noconfirm flatpak; then
                # Add Flathub repository
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                echo_success "Successfully installed Flatpak"
                log_action "INSTALL_SUCCESS" "flatpak"
                return 0
            fi
            ;;
        "zypper")
            if sudo zypper install -y flatpak; then
                # Add Flathub repository
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                echo_success "Successfully installed Flatpak"
                log_action "INSTALL_SUCCESS" "flatpak"
                return 0
            fi
            ;;
    esac
    
    echo_error "Failed to install Flatpak"
    log_action "INSTALL_FAILED" "flatpak"
    return 1
}

# Snap installation
install_snap() {
    echo_progress "Installing Snap..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            if sudo apt install -y snapd; then
                sudo systemctl enable snapd
                sudo systemctl start snapd
                echo_success "Successfully installed Snap"
                log_action "INSTALL_SUCCESS" "snapd"
                return 0
            fi
            ;;
        "dnf"|"yum")
            if sudo $PACKAGE_MANAGER install -y snapd; then
                sudo systemctl enable snapd
                sudo systemctl start snapd
                sudo ln -sf /var/lib/snapd/snap /snap
                echo_success "Successfully installed Snap"
                log_action "INSTALL_SUCCESS" "snapd"
                return 0
            fi
            ;;
        "yay")
            if yay -S --noconfirm snapd; then
                sudo systemctl enable snapd
                sudo systemctl start snapd
                sudo ln -sf /var/lib/snapd/snap /snap
                echo_success "Successfully installed Snap"
                log_action "INSTALL_SUCCESS" "snapd"
                return 0
            fi
            ;;
        "zypper")
            if sudo zypper install -y snapd; then
                sudo systemctl enable snapd
                sudo systemctl start snapd
                sudo ln -sf /var/lib/snapd/snap /snap
                echo_success "Successfully installed Snap"
                log_action "INSTALL_SUCCESS" "snapd"
                return 0
            fi
            ;;
    esac
    
    echo_error "Failed to install Snap"
    log_action "INSTALL_FAILED" "snapd"
    return 1
}

# Placeholder functions for apps that need specific implementation
install_zoom() {
    echo_info "Zoom installation requires manual download from https://zoom.us/download"
    return 1
}

install_slack() {
    echo_info "Slack installation requires manual download from https://slack.com/downloads"
    return 1
}

install_spotify() {
    echo_info "Spotify installation requires manual download from https://www.spotify.com/download"
    return 1
}

install_steam() {
    echo_info "Steam installation requires manual download from https://store.steampowered.com"
    return 1
}

install_docker_compose() {
    echo_info "Docker Compose is now included with Docker installation"
    return 0
}
