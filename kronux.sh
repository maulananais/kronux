#!/bin/bash
# KRONUX - Kernel Runtime Operations for Linux
# Author: Maulana Nais
# License: MIT
# Version: 2.0
# 
# Standalone version - All modules combined for curl execution
# Usage: curl -sL https://raw.githubusercontent.com/maulananais/kronux/main/kronux.sh | bash

#==============================================================================
# CONFIGURATION
#==============================================================================

# Get the script directory (for standalone mode, use temp directory)
if [[ -n "${BASH_SOURCE[0]}" ]] && [[ "${BASH_SOURCE[0]}" != "bash" ]] && [[ "${BASH_SOURCE[0]}" != "/dev/stdin" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Running via curl | bash or similar - use temp directory
    SCRIPT_DIR="/tmp/kronux-$$"
    mkdir -p "$SCRIPT_DIR/logs"
fi

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
KRONUX_VERSION="2.0"

# Repository settings
KRONUX_REPO_URL="https://github.com/maulananais/kronux.git"
KRONUX_REPO_DIR=""

# Non-interactive mode detection
NON_INTERACTIVE=0
FORCE_INTERACTIVE=0

# Check for force-interactive flag
for arg in "$@"; do
    if [[ "$arg" == "--interactive" ]] || [[ "$arg" == "-i" ]]; then
        FORCE_INTERACTIVE=1
        echo "ℹ Forcing interactive mode due to --interactive flag"
        break
    fi
done

# Detect various non-interactive scenarios (unless forced interactive)
if [[ $FORCE_INTERACTIVE -eq 0 ]]; then
    if [[ ! -t 0 ]] || [[ ! -t 1 ]] || [[ -p /dev/stdin ]]; then
        NON_INTERACTIVE=1
    fi
    
    # Additional detection for curl | bash scenarios
    if [[ "${BASH_SOURCE[0]}" == "bash" ]] || [[ "${BASH_SOURCE[0]}" == "/dev/stdin" ]] || [[ -z "${BASH_SOURCE[0]}" ]]; then
        NON_INTERACTIVE=1
    fi
fi

# Hardware detection state (for driver module)
HAS_INTEL=0
HAS_NVIDIA=0
HAS_AMD=0
IS_INTEL_NEW=0

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Display functions
show_ascii_logo() {
    echo -e "${CYAN}${BOLD}"
    echo "  ██╗  ██╗██████╗  ██████╗ ███╗   ██╗██╗   ██╗██╗  ██╗"
    echo "  ██║ ██╔╝██╔══██╗██╔═══██╗████╗  ██║██║   ██║╚██╗██╔╝"
    echo "  █████╔╝ ██████╔╝██║   ██║██╔██╗ ██║██║   ██║ ╚███╔╝ "
    echo "  ██╔═██╗ ██╔══██╗██║   ██║██║╚██╗██║██║   ██║ ██╔██╗ "
    echo "  ██║  ██╗██║  ██║╚██████╔╝██║ ╚████║╚██████╔╝██╔╝ ██╗"
    echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${BOLD}Kernel Runtime Operations for Linux${NC}"
    echo
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
    show_ascii_logo
    echo_info "Thanks for using KRONUX!"
    echo
    
    # Show repository information
    if [[ -n "$KRONUX_REPO_DIR" && -d "$KRONUX_REPO_DIR" ]]; then
        echo_success "KRONUX Repository Downloaded!"
        echo_info "📁 Repository location: ${GREEN}$KRONUX_REPO_DIR${NC}"
        echo
        echo_info "The repository contains:"
        echo_info "  • 📖 Complete documentation"
        echo_info "  • 🔧 Modular scripts for development"
        echo_info "  • 📝 Configuration examples"
        echo_info "  • 🔄 Latest updates and features"
        echo
        echo_info "You can explore the repository with:"
        echo_info "  ${CYAN}cd $KRONUX_REPO_DIR${NC}"
        echo_info "  ${CYAN}ls -la${NC}"
        echo
        echo_info "To get updates later, run in the repository directory:"
        echo_info "  ${CYAN}git pull origin main${NC}"
        echo
    else
        echo_info "Repository was not downloaded. You can get it manually with:"
        echo_info "  ${CYAN}git clone $KRONUX_REPO_URL${NC}"
        echo
    fi
    
    echo_info "Visit: ${BLUE}https://github.com/maulananais/kronux${NC}"
    echo_info "Goodbye! 👋"
    echo
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
        "Google Chrome"|"Microsoft Edge"|"Brave Browser"|"Visual Studio Code"|"Discord"|"Zoom"|"Slack"|"Spotify"|"Steam"|"Docker"|"Flatpak"|"Snap"|"WhatsApp"|"Teams"|"Signal"|"Element"|"Notion")
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
                echo_error "Failed to uninstalled $item"
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
                echo_error "Failed to uninstalled $item"
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
        "WhatsApp")
            install_whatsapp
            ;;
        "Teams")
            install_teams
            ;;
        "Signal")
            install_signal
            ;;
        "Element")
            install_element
            ;;
        "Notion")
            install_notion
            ;;
        *)
            echo_warning "No special installation method for $item"
            return 1
            ;;
    esac
}

#==============================================================================
# SPECIAL INSTALLATION FUNCTIONS
#==============================================================================

install_google_chrome() {
    echo_progress "Installing Google Chrome..."
    case "$PACKAGE_MANAGER" in
        "apt")
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
            echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
            sudo apt update && sudo apt install -y google-chrome-stable
            ;;
        "dnf"|"yum")
            sudo "$PACKAGE_MANAGER" config-manager --add-repo https://dl.google.com/linux/chrome/rpm/stable/x86_64/google-chrome.repo
            sudo "$PACKAGE_MANAGER" install -y google-chrome-stable
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm google-chrome
            ;;
        "zypper")
            sudo zypper ar http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome
            sudo zypper refresh && sudo zypper install -y google-chrome-stable
            ;;
    esac
}

install_microsoft_edge() {
    echo_progress "Installing Microsoft Edge..."
    case "$PACKAGE_MANAGER" in
        "apt")
            curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
            sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge-dev.list
            sudo apt update && sudo apt install -y microsoft-edge-stable
            ;;
        "dnf"|"yum")
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo "$PACKAGE_MANAGER" config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
            sudo "$PACKAGE_MANAGER" install -y microsoft-edge-stable
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm microsoft-edge-stable-bin
            ;;
        "zypper")
            sudo zypper ar https://packages.microsoft.com/yumrepos/edge microsoft-edge
            sudo zypper refresh && sudo zypper install -y microsoft-edge-stable
            ;;
    esac
}

install_brave_browser() {
    echo_progress "Installing Brave Browser..."
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
            sudo apt update && sudo apt install -y brave-browser
            ;;
        "dnf"|"yum")
            sudo "$PACKAGE_MANAGER" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
            sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            sudo "$PACKAGE_MANAGER" install -y brave-browser
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm brave-bin
            ;;
        "zypper")
            sudo zypper ar https://brave-browser-rpm-release.s3.brave.com/x86_64/ brave-browser
            sudo zypper refresh && sudo zypper install -y brave-browser
            ;;
    esac
}

install_vscode() {
    echo_progress "Installing Visual Studio Code..."
    case "$PACKAGE_MANAGER" in
        "apt")
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
            sudo apt update && sudo apt install -y code
            ;;
        "dnf"|"yum")
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo "$PACKAGE_MANAGER" install -y code
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm visual-studio-code-bin
            ;;
        "zypper")
            sudo zypper ar https://packages.microsoft.com/yumrepos/vscode vscode
            sudo zypper refresh && sudo zypper install -y code
            ;;
    esac
}

install_discord() {
    echo_progress "Installing Discord..."
    case "$PACKAGE_MANAGER" in
        "apt")
            wget -O discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
            sudo dpkg -i discord.deb
            sudo apt install -f -y
            rm discord.deb
            ;;
        "dnf"|"yum")
            wget -O discord.rpm "https://discordapp.com/api/download?platform=linux&format=rpm"
            sudo "$PACKAGE_MANAGER" install -y discord.rpm
            rm discord.rpm
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm discord
            ;;
        "zypper")
            wget -O discord.rpm "https://discordapp.com/api/download?platform=linux&format=rpm"
            sudo zypper install -y discord.rpm
            rm discord.rpm
            ;;
    esac
}

install_slack() {
    echo_progress "Installing Slack..."
    case "$PACKAGE_MANAGER" in
        "apt")
            wget https://downloads.slack-edge.com/linux_releases/slack-desktop-4.29.149-amd64.deb
            sudo dpkg -i slack-desktop-*.deb
            sudo apt install -f -y
            rm slack-desktop-*.deb
            ;;
        "dnf"|"yum")
            wget https://downloads.slack-edge.com/linux_releases/slack-4.29.149-0.1.el8.x86_64.rpm
            sudo "$PACKAGE_MANAGER" install -y slack-*.rpm
            rm slack-*.rpm
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm slack-desktop
            ;;
        "zypper")
            wget https://downloads.slack-edge.com/linux_releases/slack-4.29.149-0.1.el8.x86_64.rpm
            sudo zypper install -y slack-*.rpm
            rm slack-*.rpm
            ;;
    esac
}

install_zoom() {
    echo_progress "Installing Zoom..."
    case "$PACKAGE_MANAGER" in
        "apt")
            wget https://zoom.us/client/latest/zoom_amd64.deb
            sudo dpkg -i zoom_amd64.deb
            sudo apt install -f -y
            rm zoom_amd64.deb
            ;;
        "dnf"|"yum")
            wget https://zoom.us/client/latest/zoom_x86_64.rpm
            sudo "$PACKAGE_MANAGER" install -y zoom_x86_64.rpm
            rm zoom_x86_64.rpm
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm zoom
            ;;
        "zypper")
            wget https://zoom.us/client/latest/zoom_x86_64.rpm
            sudo zypper install -y zoom_x86_64.rpm
            rm zoom_x86_64.rpm
            ;;
    esac
}

install_spotify() {
    echo_progress "Installing Spotify..."
    case "$PACKAGE_MANAGER" in
        "apt")
            curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
            echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
            sudo apt update && sudo apt install -y spotify-client
            ;;
        "dnf"|"yum")
            sudo "$PACKAGE_MANAGER" config-manager --add-repo=https://negativo17.org/repos/fedora-spotify.repo
            sudo "$PACKAGE_MANAGER" install -y spotify-client
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm spotify
            ;;
        "zypper")
            sudo zypper ar -f https://negativo17.org/repos/opensuse/spotify/ spotify
            sudo zypper refresh && sudo zypper install -y spotify-client
            ;;
    esac
}

install_steam() {
    echo_progress "Installing Steam..."
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo apt update && sudo apt install -y steam
            ;;
        "dnf"|"yum")
            sudo "$PACKAGE_MANAGER" install -y steam
            ;;
        "pacman"|"yay")
            sudo pacman -S --needed lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-intel lib32-vulkan-intel
            "$PACKAGE_MANAGER" -S --noconfirm steam
            ;;
        "zypper")
            sudo zypper install -y steam
            ;;
    esac
}

install_docker() {
    echo_progress "Installing Docker..."
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo apt update
            sudo apt install -y ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
            sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl enable docker && sudo systemctl start docker
            sudo usermod -aG docker "$USER"
            ;;
        "dnf"|"yum")
            sudo "$PACKAGE_MANAGER" install -y yum-utils
            sudo "$PACKAGE_MANAGER" config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo "$PACKAGE_MANAGER" install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl enable docker && sudo systemctl start docker
            sudo usermod -aG docker "$USER"
            ;;
        "pacman"|"yay")
            sudo pacman -S --noconfirm docker
            sudo systemctl enable docker && sudo systemctl start docker
            sudo usermod -aG docker "$USER"
            ;;
        "zypper")
            sudo zypper install -y docker
            sudo systemctl enable docker && sudo systemctl start docker
            sudo usermod -aG docker "$USER"
            ;;
    esac
}

install_docker_compose() {
    echo_progress "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

install_flatpak() {
    echo_progress "Installing Flatpak..."
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo apt install -y flatpak
            ;;
        "dnf"|"yum")
            sudo "$PACKAGE_MANAGER" install -y flatpak
            ;;
        "pacman"|"yay")
            sudo pacman -S --noconfirm flatpak
            ;;
        "zypper")
            sudo zypper install -y flatpak
            ;;
    esac
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

install_snap() {
    echo_progress "Installing Snap..."
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo apt install -y snapd
            ;;
        "dnf"|"yum")
            sudo "$PACKAGE_MANAGER" install -y snapd
            sudo systemctl enable --now snapd.socket
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm snapd
            sudo systemctl enable --now snapd.socket
            ;;
        "zypper")
            sudo zypper install -y snapd
            sudo systemctl enable --now snapd.socket
            ;;
    esac
}

install_whatsapp() {
    echo_progress "Installing WhatsApp..."
    case "$PACKAGE_MANAGER" in
        "apt")
            # Install using Flatpak
            flatpak install -y flathub com.github.eneshecan.WhatsAppForLinux
            ;;
        "dnf"|"yum")
            # Install using Flatpak
            flatpak install -y flathub com.github.eneshecan.WhatsAppForLinux
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm whatsapp-nativefier
            ;;
        "zypper")
            # Install using Flatpak
            flatpak install -y flathub com.github.eneshecan.WhatsAppForLinux
            ;;
    esac
}

install_teams() {
    echo_progress "Installing Microsoft Teams..."
    case "$PACKAGE_MANAGER" in
        "apt")
            curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
            sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/ms-teams stable main" | sudo tee /etc/apt/sources.list.d/teams.list
            sudo apt update && sudo apt install -y teams
            ;;
        "dnf"|"yum")
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo "$PACKAGE_MANAGER" config-manager --add-repo https://packages.microsoft.com/yumrepos/ms-teams
            sudo "$PACKAGE_MANAGER" install -y teams
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm teams
            ;;
        "zypper")
            sudo zypper ar https://packages.microsoft.com/yumrepos/ms-teams teams
            sudo zypper refresh && sudo zypper install -y teams
            ;;
    esac
}

install_signal() {
    echo_progress "Installing Signal..."
    case "$PACKAGE_MANAGER" in
        "apt")
            wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
            cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
            echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
            sudo apt update && sudo apt install -y signal-desktop
            ;;
        "dnf"|"yum")
            # Install using Flatpak
            flatpak install -y flathub org.signal.Signal
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm signal-desktop
            ;;
        "zypper")
            # Install using Flatpak
            flatpak install -y flathub org.signal.Signal
            ;;
    esac
}

install_element() {
    echo_progress "Installing Element..."
    case "$PACKAGE_MANAGER" in
        "apt")
            wget -O element-desktop.deb https://packages.riot.im/debian/pool/main/e/element-desktop/element-desktop_1.11.30_amd64.deb
            sudo dpkg -i element-desktop.deb
            sudo apt install -f -y
            rm element-desktop.deb
            ;;
        "dnf"|"yum")
            # Install using Flatpak
            flatpak install -y flathub im.riot.Riot
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm element-desktop
            ;;
        "zypper")
            # Install using Flatpak
            flatpak install -y flathub im.riot.Riot
            ;;
    esac
}

install_notion() {
    echo_progress "Installing Notion..."
    case "$PACKAGE_MANAGER" in
        "apt")
            # Install using Flatpak
            flatpak install -y flathub notion.id.Notion
            ;;
        "dnf"|"yum")
            # Install using Flatpak
            flatpak install -y flathub notion.id.Notion
            ;;
        "pacman"|"yay")
            "$PACKAGE_MANAGER" -S --noconfirm notion-app
            ;;
        "zypper")
            # Install using Flatpak
            flatpak install -y flathub notion.id.Notion
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

#==============================================================================
# PACKAGE MANAGER DETECTION
#==============================================================================

detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v yay >/dev/null 2>&1; then
        echo "yay"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

get_distro_name() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$NAME"
    else
        echo "Unknown Linux"
    fi
}

select_package_manager() {
    clear
    show_header "PACKAGE MANAGER SELECTION"
    
    local detected_pm=$(detect_package_manager)
    local distro_name=$(get_distro_name)
    
    echo_info "Detected Linux Distribution: $distro_name"
    
    if [[ "$detected_pm" != "unknown" ]]; then
        echo_success "Auto-detected package manager: $detected_pm"
        echo
        echo -n "Use auto-detected package manager? [Y/n]: "
        read -r response
        case "$response" in
            [nN][oO]|[nN]) 
                echo_info "Please select manually..."
                ;;
            *)
                PACKAGE_MANAGER="$detected_pm"
                echo_success "Using package manager: $PACKAGE_MANAGER"
                sleep 1
                push_nav show_main_menu
                show_main_menu
                return
                ;;
        esac
    fi
    
    echo_warning "Please select your package manager manually:"
    echo_menu_item "1" "apt (Debian, Ubuntu, Linux Mint)"
    echo_menu_item "2" "dnf (Fedora, CentOS 8+, RHEL 8+)"
    echo_menu_item "3" "yum (CentOS 7, RHEL 7, older Fedora)"
    echo_menu_item "4" "pacman (Arch Linux, Manjaro)"
    echo_menu_item "5" "yay (Arch Linux with AUR support)"
    echo_menu_item "6" "zypper (openSUSE, SUSE Linux Enterprise)"
    echo_menu_item "0" "Exit"
    echo
    
    read -p "Enter your choice [0-6]: " pm_choice
    
    case $pm_choice in
        1) PACKAGE_MANAGER="apt" ;;
        2) PACKAGE_MANAGER="dnf" ;;
        3) PACKAGE_MANAGER="yum" ;;
        4) PACKAGE_MANAGER="pacman" ;;
        5) PACKAGE_MANAGER="yay" ;;
        6) PACKAGE_MANAGER="zypper" ;;
        0|exit|Exit) exit_toolkit ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; select_package_manager; return ;;
    esac
    
    echo_success "Selected package manager: $PACKAGE_MANAGER"
    sleep 1
    
    push_nav show_main_menu
    show_main_menu
}

# Package name mapping function
get_package_name() {
    local generic_name="$1"
    case "$PACKAGE_MANAGER" in
        "apt") 
            case "$generic_name" in 
                "Visual Studio Code") echo "code" ;;
                "VSCodium") echo "codium" ;;
                "Neovim") echo "neovim" ;;
                "Vim") echo "vim" ;;
                "Git") echo "git" ;;
                "Node.js & NPM") echo "nodejs npm" ;;
                "Python 3") echo "python3" ;;
                "Python PIP") echo "python3-pip" ;;
                "Docker") echo "docker.io" ;;
                "Docker Compose") echo "docker-compose" ;;
                "cURL") echo "curl" ;;
                "Wget") echo "wget" ;;
                "JQ") echo "jq" ;;
                "GCC") echo "gcc" ;;
                "Make") echo "make" ;;
                "CMake") echo "cmake" ;;
                "Flatpak") echo "flatpak" ;;
                "Snap") echo "snapd" ;;
                "Zsh") echo "zsh" ;;
                "Fish Shell") echo "fish" ;;
                "Firefox") echo "firefox" ;;
                "Google Chrome") echo "google-chrome-stable" ;;
                "Chromium") echo "chromium-browser" ;;
                "Brave Browser") echo "brave-browser" ;;
                "Microsoft Edge") echo "microsoft-edge-stable" ;;
                "Opera") echo "opera-stable" ;;
                "Vivaldi") echo "vivaldi-stable" ;;
                "Tor Browser") echo "torbrowser-launcher" ;;
                "Lynx") echo "lynx" ;;
                "Links2") echo "links2" ;;
                "VLC Media Player") echo "vlc" ;;
                "MPV") echo "mpv" ;;
                "MPlayer") echo "mplayer" ;;
                "Audacity") echo "audacity" ;;
                "GIMP") echo "gimp" ;;
                "Inkscape") echo "inkscape" ;;
                "Krita") echo "krita" ;;
                "Blender") echo "blender" ;;
                "OBS Studio") echo "obs-studio" ;;
                "Kdenlive") echo "kdenlive" ;;
                "Handbrake") echo "handbrake" ;;
                "FFmpeg") echo "ffmpeg" ;;
                "ImageMagick") echo "imagemagick" ;;
                "Cheese") echo "cheese" ;;
                "Htop") echo "htop" ;;
                "Btop") echo "btop" ;;
                "Neofetch") echo "neofetch" ;;
                "Fastfetch") echo "fastfetch" ;;
                "Screenfetch") echo "screenfetch" ;;
                "Tree") echo "tree" ;;
                "Ranger") echo "ranger" ;;
                "Midnight Commander") echo "mc" ;;
                "Tmux") echo "tmux" ;;
                "Screen") echo "screen" ;;
                "Rsync") echo "rsync" ;;
                "Gparted") echo "gparted" ;;
                "Timeshift") echo "timeshift" ;;
                "Bleachbit") echo "bleachbit" ;;
                "Stacer") echo "stacer" ;;
                "Synaptic") echo "synaptic" ;;
                "UFW") echo "ufw" ;;
                "Gufw") echo "gufw" ;;
                "ClamAV") echo "clamav" ;;
                "Rkhunter") echo "rkhunter" ;;
                "Fail2ban") echo "fail2ban" ;;
                "LibreOffice") echo "libreoffice" ;;
                "OnlyOffice") echo "onlyoffice-desktopeditors" ;;
                "Emacs") echo "emacs" ;;
                "Nano") echo "nano" ;;
                "Gedit") echo "gedit" ;;
                "Kate") echo "kate" ;;
                "Sublime Text") echo "sublime-text" ;;
                "Atom") echo "atom" ;;
                "Typora") echo "typora" ;;
                "Obsidian") echo "obsidian" ;;
                "Taskwarrior") echo "taskwarrior" ;;
                "Calcurse") echo "calcurse" ;;
                "ALSA Utils") echo "alsa-utils" ;;
                "PulseAudio") echo "pulseaudio" ;;
                "PipeWire") echo "pipewire" ;;
                "JACK Audio") echo "jackd2" ;;
                "Pavucontrol") echo "pavucontrol" ;;
                "Alsamixer") echo "alsa-utils" ;;
                "Qjackctl") echo "qjackctl" ;;
                "Cadence") echo "cadence" ;;
                "Carla") echo "carla" ;;
                "Ardour") echo "ardour" ;;
                "Rosegarden") echo "rosegarden" ;;
                "MuseScore") echo "musescore" ;;
                # Communication Apps
                "Discord") echo "discord" ;;
                "Slack") echo "slack-desktop" ;;
                "Telegram") echo "telegram-desktop" ;;
                "WhatsApp") echo "whatsapp-for-linux" ;;
                "Skype") echo "skypeforlinux" ;;
                "Zoom") echo "zoom" ;;
                "Teams") echo "teams" ;;
                "Thunderbird") echo "thunderbird" ;;
                "Evolution") echo "evolution" ;;
                "Pidgin") echo "pidgin" ;;
                "HexChat") echo "hexchat" ;;
                "Weechat") echo "weechat" ;;
                "Signal") echo "signal-desktop" ;;
                "Element") echo "element-desktop" ;;
                # Productivity Apps
                "Notion") echo "notion-app" ;;
                "Evernote") echo "evernote" ;;
                "Simplenote") echo "simplenote" ;;
                "Todoist") echo "todoist" ;;
                "Zettlr") echo "zettlr" ;;
                *) echo "${generic_name,,}" ;;
            esac 
            ;;
        "dnf"|"yum") 
            case "$generic_name" in 
                "Visual Studio Code") echo "code" ;;
                "VSCodium") echo "codium" ;;
                "Neovim") echo "neovim" ;;
                "Vim") echo "vim" ;;
                "Git") echo "git" ;;
                "Node.js & NPM") echo "nodejs npm" ;;
                "Python 3") echo "python3" ;;
                "Python PIP") echo "python3-pip" ;;
                "Docker") echo "docker" ;;
                "Docker Compose") echo "docker-compose" ;;
                "cURL") echo "curl" ;;
                "Wget") echo "wget" ;;
                "JQ") echo "jq" ;;
                "GCC") echo "gcc" ;;
                "Make") echo "make" ;;
                "CMake") echo "cmake" ;;
                "Flatpak") echo "flatpak" ;;
                "Snap") echo "snapd" ;;
                "Zsh") echo "zsh" ;;
                "Fish Shell") echo "fish" ;;
                "Firefox") echo "firefox" ;;
                "Google Chrome") echo "google-chrome-stable" ;;
                "Chromium") echo "chromium" ;;
                "Brave Browser") echo "brave-browser" ;;
                "Microsoft Edge") echo "microsoft-edge-stable" ;;
                "Opera") echo "opera-stable" ;;
                "Vivaldi") echo "vivaldi-stable" ;;
                "Tor Browser") echo "torbrowser-launcher" ;;
                "Lynx") echo "lynx" ;;
                "Links2") echo "links" ;;
                "VLC Media Player") echo "vlc" ;;
                "MPV") echo "mpv" ;;
                "MPlayer") echo "mplayer" ;;
                "Audacity") echo "audacity" ;;
                "GIMP") echo "gimp" ;;
                "Inkscape") echo "inkscape" ;;
                "Krita") echo "krita" ;;
                "Blender") echo "blender" ;;
                "OBS Studio") echo "obs-studio" ;;
                "Kdenlive") echo "kdenlive" ;;
                "Handbrake") echo "HandBrake-gui" ;;
                "FFmpeg") echo "ffmpeg" ;;
                "ImageMagick") echo "ImageMagick" ;;
                "Cheese") echo "cheese" ;;
                "Htop") echo "htop" ;;
                "Btop") echo "btop" ;;
                "Neofetch") echo "neofetch" ;;
                "Fastfetch") echo "fastfetch" ;;
                "Screenfetch") echo "screenfetch" ;;
                "Tree") echo "tree" ;;
                "Ranger") echo "ranger" ;;
                "Midnight Commander") echo "mc" ;;
                "Tmux") echo "tmux" ;;
                "Screen") echo "screen" ;;
                "Rsync") echo "rsync" ;;
                "Gparted") echo "gparted" ;;
                "Timeshift") echo "timeshift" ;;
                "Bleachbit") echo "bleachbit" ;;
                "Stacer") echo "stacer" ;;
                "Synaptic") echo "synaptic" ;;
                "UFW") echo "ufw" ;;
                "Gufw") echo "gufw" ;;
                "ClamAV") echo "clamav" ;;
                "Rkhunter") echo "rkhunter" ;;
                "Fail2ban") echo "fail2ban" ;;
                "LibreOffice") echo "libreoffice" ;;
                "OnlyOffice") echo "onlyoffice-desktopeditors" ;;
                "Emacs") echo "emacs" ;;
                "Nano") echo "nano" ;;
                "Gedit") echo "gedit" ;;
                "Kate") echo "kate" ;;
                "Sublime Text") echo "sublime-text" ;;
                "Atom") echo "atom" ;;
                "Typora") echo "typora" ;;
                "Obsidian") echo "obsidian" ;;
                "Taskwarrior") echo "task" ;;
                "Calcurse") echo "calcurse" ;;
                "ALSA Utils") echo "alsa-utils" ;;
                "PulseAudio") echo "pulseaudio" ;;
                "PipeWire") echo "pipewire" ;;
                "JACK Audio") echo "jack-audio-connection-kit" ;;
                "Pavucontrol") echo "pavucontrol" ;;
                "Alsamixer") echo "alsa-utils" ;;
                "Qjackctl") echo "qjackctl" ;;
                "Cadence") echo "cadence" ;;
                "Carla") echo "carla" ;;
                "Ardour") echo "ardour6" ;;
                "Rosegarden") echo "rosegarden" ;;
                "MuseScore") echo "musescore" ;;
                # Communication Apps
                "Discord") echo "discord" ;;
                "Slack") echo "slack" ;;
                "Telegram") echo "telegram-desktop" ;;
                "WhatsApp") echo "whatsapp-for-linux" ;;
                "Skype") echo "skypeforlinux" ;;
                "Zoom") echo "zoom" ;;
                "Teams") echo "teams-for-linux" ;;
                "Thunderbird") echo "thunderbird" ;;
                "Evolution") echo "evolution" ;;
                "Pidgin") echo "pidgin" ;;
                "HexChat") echo "hexchat" ;;
                "Weechat") echo "weechat" ;;
                "Signal") echo "signal-desktop" ;;
                "Element") echo "element-desktop" ;;
                # Productivity Apps
                "Notion") echo "notion-app-enhanced" ;;
                "Evernote") echo "evernote" ;;
                "Simplenote") echo "simplenote" ;;
                "Todoist") echo "todoist-appimage" ;;
                "Zettlr") echo "zettlr" ;;
                *) echo "${generic_name,,}" ;;
            esac 
            ;;
        "pacman"|"yay") 
            case "$generic_name" in 
                "Visual Studio Code") echo "visual-studio-code-bin" ;;
                "VSCodium") echo "vscodium-bin" ;;
                "Neovim") echo "neovim" ;;
                "Vim") echo "vim" ;;
                "Git") echo "git" ;;
                "Node.js & NPM") echo "nodejs npm" ;;
                "Python 3") echo "python" ;;
                "Python PIP") echo "python-pip" ;;
                "Docker") echo "docker" ;;
                "Docker Compose") echo "docker-compose" ;;
                "cURL") echo "curl" ;;
                "Wget") echo "wget" ;;
                "JQ") echo "jq" ;;
                "GCC") echo "gcc" ;;
                "Make") echo "make" ;;
                "CMake") echo "cmake" ;;
                "Flatpak") echo "flatpak" ;;
                "Snap") echo "snapd" ;;
                "Zsh") echo "zsh" ;;
                "Fish Shell") echo "fish" ;;
                "Firefox") echo "firefox" ;;
                "Google Chrome") echo "google-chrome" ;;
                "Chromium") echo "chromium" ;;
                "Brave Browser") echo "brave-bin" ;;
                "Microsoft Edge") echo "microsoft-edge-stable-bin" ;;
                "Opera") echo "opera" ;;
                "Vivaldi") echo "vivaldi" ;;
                "Tor Browser") echo "torbrowser-launcher" ;;
                "Lynx") echo "lynx" ;;
                "Links2") echo "links" ;;
                "VLC Media Player") echo "vlc" ;;
                "MPV") echo "mpv" ;;
                "MPlayer") echo "mplayer" ;;
                "Audacity") echo "audacity" ;;
                "GIMP") echo "gimp" ;;
                "Inkscape") echo "inkscape" ;;
                "Krita") echo "krita" ;;
                "Blender") echo "blender" ;;
                "OBS Studio") echo "obs-studio" ;;
                "Kdenlive") echo "kdenlive" ;;
                "Handbrake") echo "handbrake" ;;
                "FFmpeg") echo "ffmpeg" ;;
                "ImageMagick") echo "imagemagick" ;;
                "Cheese") echo "cheese" ;;
                "Htop") echo "htop" ;;
                "Btop") echo "btop" ;;
                "Neofetch") echo "neofetch" ;;
                "Fastfetch") echo "fastfetch" ;;
                "Screenfetch") echo "screenfetch" ;;
                "Tree") echo "tree" ;;
                "Ranger") echo "ranger" ;;
                "Midnight Commander") echo "mc" ;;
                "Tmux") echo "tmux" ;;
                "Screen") echo "screen" ;;
                "Rsync") echo "rsync" ;;
                "Gparted") echo "gparted" ;;
                "Timeshift") echo "timeshift" ;;
                "Bleachbit") echo "bleachbit" ;;
                "Stacer") echo "stacer" ;;
                "Synaptic") echo "synaptic" ;;
                "UFW") echo "ufw" ;;
                "Gufw") echo "gufw" ;;
                "ClamAV") echo "clamav" ;;
                "Rkhunter") echo "rkhunter" ;;
                "Fail2ban") echo "fail2ban" ;;
                "LibreOffice") echo "libreoffice-fresh" ;;
                "OnlyOffice") echo "onlyoffice-bin" ;;
                "Emacs") echo "emacs" ;;
                "Nano") echo "nano" ;;
                "Gedit") echo "gedit" ;;
                "Kate") echo "kate" ;;
                "Sublime Text") echo "sublime-text-4" ;;
                "Atom") echo "atom" ;;
                "Typora") echo "typora" ;;
                "Obsidian") echo "obsidian" ;;
                "Taskwarrior") echo "task" ;;
                "Calcurse") echo "calcurse" ;;
                "ALSA Utils") echo "alsa-utils" ;;
                "PulseAudio") echo "pulseaudio" ;;
                "PipeWire") echo "pipewire" ;;
                "JACK Audio") echo "jack2" ;;
                "Pavucontrol") echo "pavucontrol" ;;
                "Alsamixer") echo "alsa-utils" ;;
                "Qjackctl") echo "qjackctl" ;;
                "Cadence") echo "cadence" ;;
                "Carla") echo "carla" ;;
                "Ardour") echo "ardour" ;;
                "Rosegarden") echo "rosegarden" ;;
                "MuseScore") echo "musescore" ;;
                # Communication Apps
                "Discord") echo "discord" ;;
                "Slack") echo "slack-desktop" ;;
                "Telegram") echo "telegram-desktop" ;;
                "WhatsApp") echo "whatsapp-nativefier" ;;
                "Skype") echo "skypeforlinux-stable-bin" ;;
                "Zoom") echo "zoom" ;;
                "Teams") echo "teams" ;;
                "Thunderbird") echo "thunderbird" ;;
                "Evolution") echo "evolution" ;;
                "Pidgin") echo "pidgin" ;;
                "HexChat") echo "hexchat" ;;
                "Weechat") echo "weechat" ;;
                "Signal") echo "signal-desktop" ;;
                "Element") echo "element-desktop" ;;
                # Productivity Apps
                "Notion") echo "notion-app" ;;
                "Evernote") echo "evernote" ;;
                "Simplenote") echo "simplenote-electron-bin" ;;
                "Todoist") echo "todoist-appimage" ;;
                "Zettlr") echo "zettlr-bin" ;;
                *) echo "${generic_name,,}" ;;
            esac 
            ;;
        "zypper") 
            case "$generic_name" in 
                "Visual Studio Code") echo "code" ;;
                "VSCodium") echo "codium" ;;
                "Neovim") echo "neovim" ;;
                "Vim") echo "vim" ;;
                "Git") echo "git" ;;
                "Node.js & NPM") echo "nodejs18 npm18" ;;
                "Python 3") echo "python3" ;;
                "Python PIP") echo "python3-pip" ;;
                "Docker") echo "docker" ;;
                "Docker Compose") echo "docker-compose" ;;
                "cURL") echo "curl" ;;
                "Wget") echo "wget" ;;
                "JQ") echo "jq" ;;
                "GCC") echo "gcc" ;;
                "Make") echo "make" ;;
                "CMake") echo "cmake" ;;
                "Flatpak") echo "flatpak" ;;
                "Snap") echo "snapd" ;;
                "Zsh") echo "zsh" ;;
                "Fish Shell") echo "fish" ;;
                "Firefox") echo "firefox" ;;
                "Google Chrome") echo "google-chrome-stable" ;;
                "Chromium") echo "chromium" ;;
                "Brave Browser") echo "brave-browser" ;;
                "Microsoft Edge") echo "microsoft-edge-stable" ;;
                "Opera") echo "opera" ;;
                "Vivaldi") echo "vivaldi" ;;
                "Tor Browser") echo "torbrowser-launcher" ;;
                "Lynx") echo "lynx" ;;
                "Links2") echo "links" ;;
                "VLC Media Player") echo "vlc" ;;
                "MPV") echo "mpv" ;;
                "MPlayer") echo "mplayer" ;;
                "Audacity") echo "audacity" ;;
                "GIMP") echo "gimp" ;;
                "Inkscape") echo "inkscape" ;;
                "Krita") echo "krita" ;;
                "Blender") echo "blender" ;;
                "OBS Studio") echo "obs-studio" ;;
                "Kdenlive") echo "kdenlive5" ;;
                "Handbrake") echo "handbrake" ;;
                "FFmpeg") echo "ffmpeg" ;;
                "ImageMagick") echo "ImageMagick" ;;
                "Cheese") echo "cheese" ;;
                "Htop") echo "htop" ;;
                "Btop") echo "btop" ;;
                "Neofetch") echo "neofetch" ;;
                "Fastfetch") echo "fastfetch" ;;
                "Screenfetch") echo "screenfetch" ;;
                "Tree") echo "tree" ;;
                "Ranger") echo "ranger" ;;
                "Midnight Commander") echo "mc" ;;
                "Tmux") echo "tmux" ;;
                "Screen") echo "screen" ;;
                "Rsync") echo "rsync" ;;
                "Gparted") echo "gparted" ;;
                "Timeshift") echo "timeshift" ;;
                "Bleachbit") echo "bleachbit" ;;
                "Stacer") echo "stacer" ;;
                "Synaptic") echo "synaptic" ;;
                "UFW") echo "ufw" ;;
                "Gufw") echo "gufw" ;;
                "ClamAV") echo "clamav" ;;
                "Rkhunter") echo "rkhunter" ;;
                "Fail2ban") echo "fail2ban" ;;
                "LibreOffice") echo "libreoffice" ;;
                "OnlyOffice") echo "onlyoffice-desktopeditors" ;;
                "Emacs") echo "emacs" ;;
                "Nano") echo "nano" ;;
                "Gedit") echo "gedit" ;;
                "Kate") echo "kate" ;;
                "Sublime Text") echo "sublime-text" ;;
                "Atom") echo "atom" ;;
                "Typora") echo "typora" ;;
                "Obsidian") echo "obsidian" ;;
                "Taskwarrior") echo "taskwarrior" ;;
                "Calcurse") echo "calcurse" ;;
                "ALSA Utils") echo "alsa-utils" ;;
                "PulseAudio") echo "pulseaudio" ;;
                "PipeWire") echo "pipewire" ;;
                "JACK Audio") echo "jack" ;;
                "Pavucontrol") echo "pavucontrol" ;;
                "Alsamixer") echo "alsa-utils" ;;
                "Qjackctl") echo "qjackctl" ;;
                "Cadence") echo "cadence" ;;
                "Carla") echo "carla" ;;
                "Ardour") echo "ardour" ;;
                "Rosegarden") echo "rosegarden" ;;
                "MuseScore") echo "musescore" ;;
                # Communication Apps
                "Discord") echo "discord" ;;
                "Slack") echo "slack-desktop" ;;
                "Telegram") echo "telegram-desktop" ;;
                "WhatsApp") echo "whatsapp-for-linux" ;;
                "Skype") echo "skypeforlinux" ;;
                "Zoom") echo "zoom" ;;
                "Teams") echo "teams" ;;
                "Thunderbird") echo "thunderbird" ;;
                "Evolution") echo "evolution" ;;
                "Pidgin") echo "pidgin" ;;
                "HexChat") echo "hexchat" ;;
                "Weechat") echo "weechat" ;;
                "Signal") echo "signal-desktop" ;;
                "Element") echo "element-desktop" ;;
                # Productivity Apps
                "Notion") echo "notion-app" ;;
                "Evernote") echo "evernote" ;;
                "Simplenote") echo "simplenote" ;;
                "Todoist") echo "todoist" ;;
                "Zettlr") echo "zettlr" ;;
                *) echo "${generic_name,,}" ;;
            esac 
            ;;
        *) echo "${generic_name,,}" ;;
    esac
}

#==============================================================================
# GRAPHICS DRIVER MODULE (Simplified)
#==============================================================================

# Check for required tools
check_dependencies() {
    local missing_deps=()
    for cmd in lspci lsmod grep cut sort uniq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo_error "Missing required dependencies: ${missing_deps[*]}"
        case "$PACKAGE_MANAGER" in
            "apt") install_package "pciutils" ;;
            "dnf"|"yum") install_package "pciutils" ;;
            "pacman"|"yay") install_package "pciutils" ;;
            "zypper") install_package "pciutils" ;;
        esac
        return 1
    fi
    return 0
}

# Function to detect all graphics hardware
detect_graphics_hardware() {
    echo_info "Detecting graphics hardware..."
    local vga_devices=$(lspci | grep -i "VGA")
    
    # Reset hardware detection flags
    HAS_INTEL=0
    HAS_NVIDIA=0
    HAS_AMD=0
    IS_INTEL_NEW=0
    
    # Process each VGA device
    while IFS= read -r device; do
        # Detect Intel GPUs
        if echo "$device" | grep -i "Intel" >/dev/null; then
            local intel_model=$(echo "$device" | cut -d: -f3)
            echo_success "Found Intel GPU: $intel_model"
            HAS_INTEL=1
            # Detect if it's a newer Intel GPU
            if echo "$intel_model" | grep -iE "HD Graphics (4|5|6)|UHD Graphics|Iris|Arc" >/dev/null; then
                IS_INTEL_NEW=1
            fi
            continue
        fi
        
        # Detect NVIDIA GPUs
        if echo "$device" | grep -i "NVIDIA" | grep -v "nForce" >/dev/null; then
            local nvidia_model=$(echo "$device" | cut -d: -f3)
            echo_success "Found NVIDIA GPU: $nvidia_model"
            HAS_NVIDIA=1
            continue
        fi
        
        # Detect AMD GPUs
        if echo "$device" | grep -iE "AMD|ATI" >/dev/null; then
            local amd_model=$(echo "$device" | cut -d: -f3)
            echo_success "Found AMD GPU: $amd_model"
            HAS_AMD=1
            continue
        fi
    done <<< "$vga_devices"
    
    # Check for NVIDIA GPUs separately
    if ! [[ "$HAS_NVIDIA" == "1" ]] && lspci | grep -i "NVIDIA" | grep -v "nForce" >/dev/null; then
        local nvidia_model=$(lspci | grep -i "NVIDIA" | grep -v "nForce" | cut -d: -f3)
        echo_success "Found NVIDIA GPU: $nvidia_model"
        HAS_NVIDIA=1
    fi
    
    # Check for no GPUs detected
    if [[ "$HAS_INTEL" == "0" && "$HAS_NVIDIA" == "0" && "$HAS_AMD" == "0" ]]; then
        echo_error "No graphics hardware detected!"
        return 1
    fi
    
    return 0
}

#==============================================================================
# MENU SYSTEM
#==============================================================================

# Main menu
show_main_menu() {
    clear
    show_header "MAIN MENU"
    
    echo_menu_item "1" "Install a Package"
    echo_menu_item "2" "Uninstall a Package"
    echo_menu_item "3" "Enable a Service"
    echo_menu_item "4" "Disable a Service"
    echo_menu_item "5" "App/Driver Modules"
    echo_menu_item "6" "Graphics Drivers"
    echo_menu_item "7" "Advanced Uninstaller"
    echo_menu_item "8" "System Utilities"
    echo_menu_item "0" "Exit"
    echo
    read -p "Enter your choice [0-8]: " main_choice
    
    case $main_choice in
        1) show_install_package_menu ;;
        2) show_uninstall_package_menu ;;
        3) show_enable_service_menu ;;
        4) show_disable_service_menu ;;
        5) show_module_menu ;;
        6) show_graphics_drivers ;;
        7) show_uninstaller_menu ;;
        8) show_system_utilities ;;
        0|back|Back|exit|Exit) exit_toolkit ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; show_main_menu ;;
    esac
}

# Graphics drivers menu
show_graphics_drivers() {
    clear
    show_header "GRAPHICS DRIVERS"

    # Check dependencies and hardware
    if ! check_dependencies; then
        echo_error "Missing required dependencies."
        sleep 2
        show_main_menu
        return
    fi

    if ! detect_graphics_hardware; then
        echo_error "Failed to detect graphics hardware."
        sleep 2
        show_main_menu
        return
    fi

    echo_menu_item "1" "Install NVIDIA Drivers"
    echo_menu_item "2" "Install AMD Drivers"
    echo_menu_item "3" "Install Intel Drivers"
    echo_menu_item "4" "Install Mesa Drivers"
    echo_menu_item "5" "Install Vulkan Support"
    echo_menu_item "6" "Install 32-bit Libraries"
    echo_menu_item "7" "Hardware Acceleration Menu"
    echo_menu_item "0" "Back"
    echo
    read -p "Enter your choice [0-7]: " driver_choice

    case $driver_choice in
        1)
            if validate_hardware "nvidia"; then
                install_graphics_driver "nvidia"
            fi
            ;;
        2)
            if validate_hardware "amd"; then
                install_graphics_driver "amd"
            fi
            ;;
        3)
            if validate_hardware "intel"; then
                install_graphics_driver "intel"
            fi
            ;;
        4)
            install_graphics_driver "mesa"
            ;;
        5)
            install_graphics_driver "vulkan"
            ;;
        6)
            install_graphics_driver "lib32"
            ;;
        7)
            show_hw_acceleration_menu
            return
            ;;
        0|back|Back)
            show_main_menu
            return
            ;;
        *)
            echo_error "Invalid choice. Please try again."
            sleep 1
            ;;
    esac

    # Return to this menu after action completes
    show_graphics_drivers
}

# Quick package menus
show_install_package_menu() {
    clear
    show_header "INSTALL PACKAGE"
    echo_info "Enter package name to install:"
    read -p "Package name: " package_name
    
    if [[ -n "$package_name" ]]; then
        echo_progress "Installing $package_name..."
        if install_package "$package_name"; then
            echo_success "Successfully installed $package_name"
            log_action "INSTALL_SUCCESS" "$package_name"
        else
            echo_error "Failed to install $package_name"
            log_action "INSTALL_FAILED" "$package_name"
        fi
        sleep 2
    fi
    
    show_main_menu
}

show_uninstall_package_menu() {
    clear
    show_header "UNINSTALL PACKAGE"
    echo_info "Enter package name to uninstall:"
    read -p "Package name: " package_name
    
    if [[ -n "$package_name" ]]; then
        echo_progress "Uninstalling $package_name..."
        case "$PACKAGE_MANAGER" in
            "apt") 
                if sudo apt remove -y "$package_name"; then
                    echo_success "Successfully uninstalled $package_name"
                    log_action "UNINSTALL_SUCCESS" "$package_name"
                else
                    echo_error "Failed to uninstall $package_name"
                    log_action "UNINSTALL_FAILED" "$package_name"
                fi
                ;;
            "dnf"|"yum") 
                if sudo "$PACKAGE_MANAGER" remove -y "$package_name"; then
                    echo_success "Successfully uninstalled $package_name"
                    log_action "UNINSTALL_SUCCESS" "$package_name"
                else
                    echo_error "Failed to uninstall $package_name"
                    log_action "UNINSTALL_FAILED" "$package_name"
                fi
                ;;
            "pacman"|"yay") 
                if sudo pacman -R --noconfirm "$package_name"; then
                    echo_success "Successfully uninstalled $package_name"
                    log_action "UNINSTALL_SUCCESS" "$package_name"
                else
                    echo_error "Failed to uninstall $package_name"
                    log_action "UNINSTALL_FAILED" "$package_name"
                fi
                ;;
            "zypper") 
                if sudo zypper remove -y "$package_name"; then
                    echo_success "Successfully uninstalled $package_name"
                    log_action "UNINSTALL_SUCCESS" "$package_name"
                else
                    echo_error "Failed to uninstall $package_name"
                    log_action "UNINSTALL_FAILED" "$package_name"
                fi
                ;;
        esac
        sleep 2
    fi
    
    show_main_menu
}

show_enable_service_menu() {
    clear
    show_header "ENABLE SERVICE"
    echo_info "Enter service name to enable:"
    read -p "Service name: " service_name
    
    if [[ -n "$service_name" ]]; then
        echo_progress "Enabling $service_name..."
        if sudo systemctl enable "$service_name" && sudo systemctl start "$service_name"; then
            echo_success "Successfully enabled $service_name"
        else
            echo_error "Failed to enable $service_name"
        fi
        sleep 2
    fi
    
    show_main_menu
}

show_disable_service_menu() {
    clear
    show_header "DISABLE SERVICE"
    echo_info "Enter service name to disable:"
    read -p "Service name: " service_name
    
    if [[ -n "$service_name" ]]; then
        echo_progress "Disabling $service_name..."
        if sudo systemctl stop "$service_name" && sudo systemctl disable "$service_name"; then
            echo_success "Successfully disabled $service_name"
        else
            echo_error "Failed to disable $service_name"
        fi
        sleep 2
    fi
    
    show_main_menu
}

show_module_menu() {
    clear
    show_header "SELECT MODULE"
    
    echo_menu_item "1" "Developer Tools"
    echo_menu_item "2" "Web Browsers"
    echo_menu_item "3" "Multimedia Tools"
    echo_menu_item "4" "Communication Apps"
    echo_menu_item "5" "System Tools"
    echo_menu_item "6" "Productivity Apps"
    echo_menu_item "7" "Graphics Drivers"
    echo_menu_item "8" "Audio Drivers"
    echo_menu_item "9" "System Tweaks"
    echo_menu_item "10" "System Cleanup"
    echo_menu_item "0" "Back"
    echo
    read -p "Enter your choice [0-10]: " mod_choice
    
    case $mod_choice in
        1) show_developer_tools ;;
        2) show_web_browsers ;;
        3) show_multimedia_tools ;;
        4) show_communication_apps ;;
        5) show_system_tools ;;
        6) show_productivity_apps ;;
        7) show_graphics_drivers ;;
        8) show_audio_drivers ;;
        9) show_system_tweaks ;;
        10) show_system_cleanup ;;
        0|back|Back) show_main_menu ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; show_module_menu ;;
    esac
}

show_system_utilities() {
    clear
    show_header "SYSTEM UTILITIES"
    
    echo_menu_item "1" "Update System"
    echo_menu_item "2" "Clean Package Cache"
    echo_menu_item "3" "Show System Info"
    echo_menu_item "4" "Check Disk Usage"
    echo_menu_item "0" "Back"
    echo
    read -p "Enter your choice [0-4]: " util_choice
    
    case $util_choice in
        1) update_system ;;
        2) clean_package_cache ;;
        3) show_system_info ;;
        4) check_disk_usage ;;
        0|back|Back) show_main_menu ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; show_system_utilities ;;
    esac
}

#==============================================================================
# MODULE INSTALLATIONS (Complete Implementation)
#==============================================================================

show_developer_tools() {
    clear
    show_header "DEVELOPER TOOLS"
    local items=("Visual Studio Code" "VSCodium" "Neovim" "Vim" "Git" "Node.js & NPM" "Python 3" "Python PIP" "Docker" "Docker Compose" "cURL" "Wget" "JQ" "GCC" "Make" "CMake" "Flatpak" "Snap" "Zsh" "Fish Shell")
    show_selection_menu "Install" "DEVELOPER TOOLS" "${items[@]}"
}

show_web_browsers() {
    clear
    show_header "WEB BROWSERS"
    local items=("Firefox" "Google Chrome" "Chromium" "Brave Browser" "Microsoft Edge" "Opera" "Vivaldi" "Tor Browser" "Lynx" "Links2")
    show_selection_menu "Install" "WEB BROWSERS" "${items[@]}"
}

show_multimedia_tools() {
    clear
    show_header "MULTIMEDIA TOOLS"
    local items=("VLC Media Player" "MPV" "MPlayer" "Audacity" "GIMP" "Inkscape" "Krita" "Blender" "OBS Studio" "Kdenlive" "Handbrake" "FFmpeg" "ImageMagick" "Cheese")
    show_selection_menu "Install" "MULTIMEDIA TOOLS" "${items[@]}"
}

show_communication_apps() {
    clear
    show_header "COMMUNICATION APPS"
    local items=("Discord" "Slack" "Telegram" "WhatsApp" "Skype" "Zoom" "Teams" "Thunderbird" "Evolution" "Pidgin" "HexChat" "Weechat" "Signal" "Element")
    show_selection_menu "Install" "COMMUNICATION APPS" "${items[@]}"
}

show_system_tools() {
    clear
    show_header "SYSTEM TOOLS"
    local items=("Htop" "Btop" "Neofetch" "Fastfetch" "Screenfetch" "Tree" "Ranger" "Midnight Commander" "Tmux" "Screen" "Rsync" "Gparted" "Timeshift" "Bleachbit" "Stacer" "Synaptic" "UFW" "Gufw" "ClamAV" "Rkhunter" "Fail2ban")
    show_selection_menu "Install" "SYSTEM TOOLS" "${items[@]}"
}

#==============================================================================
# ADDITIONAL MODULE INSTALLATIONS
#==============================================================================

show_productivity_apps() {
    clear
    show_header "PRODUCTIVITY APPS"
    local items=("LibreOffice" "OnlyOffice" "Vim" "Emacs" "Nano" "Gedit" "Kate" "Sublime Text" "Atom" "Typora" "Obsidian" "Notion" "Evernote" "Simplenote" "Todoist" "Taskwarrior" "Calcurse" "Zettlr")
    show_selection_menu "Install" "PRODUCTIVITY APPS" "${items[@]}"
}

show_audio_drivers() {
    clear
    show_header "AUDIO DRIVERS"
    local items=("ALSA Utils" "PulseAudio" "PipeWire" "JACK Audio" "Pavucontrol" "Alsamixer" "Qjackctl" "Cadence" "Carla" "Ardour" "Rosegarden" "MuseScore")
    show_selection_menu "Install" "AUDIO DRIVERS" "${items[@]}"
}

show_system_tweaks() {
    clear
    show_header "SYSTEM TWEAKS"
    local items=("Install TLP" "Configure Swappiness" "Enable ZRAM" "Optimize SSD" "CPU Governor" "Reduce GRUB Timeout" "Disable Snap" "Enable Flatpak" "GNOME Tweaks" "Configure Fonts" "UFW Firewall" "System Hardening")
    show_selection_menu "Install" "SYSTEM TWEAKS" "${items[@]}"
}

show_system_cleanup() {
    clear
    show_header "SYSTEM CLEANUP"
    local items=("Clean Package Cache" "Remove Orphaned Packages" "Clean Temporary Files" "Clean Log Files" "Clean Thumbnail Cache" "Clean Trash" "Clean Browser Cache" "Clean Snap Cache" "Clean Flatpak Cache" "Vacuum Journalctl" "Clean APT Cache" "Clean DNF Cache")
    show_selection_menu "Install" "SYSTEM CLEANUP" "${items[@]}"
}

remove_orphaned_packages() {
    echo_progress "Removing orphaned packages..."
    case "$PACKAGE_MANAGER" in
        "apt") sudo apt autoremove -y ;;
        "dnf"|"yum") sudo "$PACKAGE_MANAGER" autoremove -y ;;
        "pacman") sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || echo_info "No orphaned packages found" ;;
        "yay") yay -Rns $(yay -Qtdq) 2>/dev/null || echo_info "No orphaned packages found" ;;
        "zypper") sudo zypper packages --orphaned | grep -v "No packages found" && sudo zypper remove --clean-deps $(zypper packages --orphaned | awk '/^i/ {print $5}') ;;
    esac
    echo_success "Orphaned packages removed!"
    sleep 2
}

clean_temp_files() {
    echo_progress "Cleaning temporary files..."
    sudo rm -rf /tmp/* 2>/dev/null
    sudo rm -rf /var/tmp/* 2>/dev/null
    rm -rf ~/.cache/thumbnails/* 2>/dev/null
    echo_success "Temporary files cleaned!"
    sleep 2
}

clean_log_files() {
    echo_progress "Cleaning log files..."
    sudo journalctl --vacuum-time=7d 2>/dev/null
    sudo find /var/log -name "*.log" -type f -mtime +30 -delete 2>/dev/null
    echo_success "Log files cleaned!"
    sleep 2
}

clean_all_system() {
    echo_progress "Performing complete system cleanup..."
    clean_package_cache
    remove_orphaned_packages
    clean_temp_files
    clean_log_files
    echo_success "Complete system cleanup finished!"
    sleep 2
}

# Hardware acceleration menu
show_hw_acceleration_menu() {
    clear
    show_header "HARDWARE ACCELERATION"

    echo_menu_item "1" "Install Intel Media Driver (New GPUs)"
    echo_menu_item "2" "Install Intel VA Driver (Old GPUs)"
    echo_menu_item "3" "Install AMD VA/VDPAU Drivers"
    echo_menu_item "4" "Install NVIDIA VAAPI Bridge"
    echo_menu_item "5" "Install 32-bit VA/VDPAU Support"
    echo_menu_item "6" "Install DVD Playback Support"
    echo_menu_item "7" "Install Additional Firmware"
    echo_menu_item "0" "Back"
    echo
    read -p "Enter your choice [0-7]: " accel_choice

    case $accel_choice in
        1)
            if [[ "$HAS_INTEL" == "1" ]]; then
                install_hw_acceleration "intel-new"
            else
                echo_error "No Intel GPU detected."
                sleep 2
            fi
            ;;
        2)
            if [[ "$HAS_INTEL" == "1" ]]; then
                install_hw_acceleration "intel-old"
            else
                echo_error "No Intel GPU detected."
                sleep 2
            fi
            ;;
        3)
            if [[ "$HAS_AMD" == "1" ]]; then
                install_hw_acceleration "amd"
            else
                echo_error "No AMD GPU detected."
                sleep 2
            fi
            ;;
        4)
            if [[ "$HAS_NVIDIA" == "1" ]]; then
                install_hw_acceleration "nvidia"
            else
                echo_error "No NVIDIA GPU detected."
                sleep 2
            fi
            ;;
        5)
            install_hw_acceleration "lib32"
            ;;
        6)
            install_hw_acceleration "dvd"
            ;;
        7)
            install_hw_acceleration "firmware"
            ;;
        0|back|Back)
            show_graphics_drivers
            return
            ;;
        *)
            echo_error "Invalid choice. Please try again."
            sleep 1
            ;;
    esac

    # Return to this menu after action completes
    show_hw_acceleration_menu
}

# Hardware acceleration installation function
install_hw_acceleration() {
    local accel_type="$1"
    
    echo_info "Installing $accel_type hardware acceleration..."
    
    case "$accel_type" in
        "intel-new")
            case "$PACKAGE_MANAGER" in
                "apt") install_package "intel-media-va-driver-non-free intel-media-va-driver" ;;
                "dnf") install_package "intel-media-driver" ;;
                "pacman"|"yay") install_package "intel-media-driver" ;;
                "zypper") install_package "intel-media-driver" ;;
            esac
            ;;
        "intel-old")
            case "$PACKAGE_MANAGER" in
                "apt") install_package "i965-va-driver" ;;
                "dnf") install_package "intel-vaapi-driver" ;;
                "pacman"|"yay") install_package "intel-vaapi-driver" ;;
                "zypper") install_package "intel-vaapi-driver" ;;
            esac
            ;;
        "amd")
            case "$PACKAGE_MANAGER" in
                "apt") install_package "mesa-va-drivers mesa-vdpau-drivers" ;;
                "dnf") install_package "mesa-va-drivers mesa-vdpau-drivers" ;;
                "pacman"|"yay") install_package "mesa-vdpau libva-mesa-driver" ;;
                "zypper") install_package "Mesa-libva Mesa-libvdpau" ;;
            esac
            ;;
        "nvidia")
            case "$PACKAGE_MANAGER" in
                "apt") install_package "nvidia-vaapi-driver" ;;
                "dnf") install_package "nvidia-vaapi-driver" ;;
                "pacman"|"yay") install_package "nvidia-vaapi-driver-git" ;;
                "zypper") echo_warning "NVIDIA VAAPI not available in openSUSE repos" ;;
            esac
            ;;
        "lib32")
            case "$PACKAGE_MANAGER" in
                "apt") install_package "mesa-va-drivers:i386 mesa-vdpau-drivers:i386" ;;
                "dnf") install_package "mesa-dri-drivers.i686 mesa-vulkan-drivers.i686" ;;
                "pacman"|"yay") install_package "lib32-mesa-vdpau lib32-libva-mesa-driver" ;;
                "zypper") install_package "Mesa-32bit Mesa-libGL1-32bit" ;;
            esac
            ;;
        "dvd")
            case "$PACKAGE_MANAGER" in
                "apt") install_package "libdvd-pkg" && sudo dpkg-reconfigure libdvd-pkg ;;
                "dnf") install_package "libdvdcss" ;;
                "pacman"|"yay") install_package "libdvdcss" ;;
                "zypper") install_package "libdvdcss2" ;;
            esac
            ;;
        "firmware")
            case "$PACKAGE_MANAGER" in
                "apt") install_package "firmware-linux firmware-linux-nonfree" ;;
                "dnf") install_package "linux-firmware" ;;
                "pacman"|"yay") install_package "linux-firmware" ;;
                "zypper") install_package "kernel-firmware" ;;
            esac
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo_success "Successfully installed $accel_type hardware acceleration"
        log_action "INSTALL_SUCCESS" "$accel_type-acceleration"
    else
        echo_error "Failed to install $accel_type hardware acceleration"
        log_action "INSTALL_FAILED" "$accel_type-acceleration"
    fi
}

# Enhanced graphics driver function with hardware validation
validate_hardware() {
    local driver_type="$1"
    
    case "$driver_type" in
        "nvidia")
            if [[ "$HAS_NVIDIA" != "1" ]]; then
                echo_error "No NVIDIA GPU detected."
                sleep 2
                return 1
            fi
            ;;
        "amd")
            if [[ "$HAS_AMD" != "1" ]]; then
                echo_error "No AMD GPU detected."
                sleep 2
                return 1
            fi
            ;;
        "intel")
            if [[ "$HAS_INTEL" != "1" ]]; then
                echo_error "No Intel GPU detected."
                sleep 2
                return 1
            fi
            ;;
    esac
    return 0
}

# Enhanced graphics driver installation with more options
install_graphics_driver() {
    local driver_type="$1"
    
    if [[ -z "$PACKAGE_MANAGER" ]]; then
        echo_error "Package manager not defined. Please select a package manager first."
        return 1
    fi
    
    echo_info "Installing $driver_type graphics drivers..."
    
    case "$driver_type" in
        "nvidia")
            case "$PACKAGE_MANAGER" in
                "apt") 
                    # Add NVIDIA repository and install
                    install_package "nvidia-driver nvidia-settings nvidia-prime"
                    ;;
                "dnf") 
                    # Enable RPM Fusion and install
                    install_package "akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda"
                    ;;
                "pacman"|"yay") 
                    install_package "nvidia-dkms nvidia-utils nvidia-settings nvidia-prime"
                    ;;
                "zypper") 
                    echo_info "Please use YaST for NVIDIA driver installation on openSUSE"
                    ;;
                *) echo_error "Unsupported package manager for NVIDIA drivers"; return 1 ;;
            esac
            ;;
        "amd")
            case "$PACKAGE_MANAGER" in
                "apt") 
                    install_package "xserver-xorg-video-amdgpu mesa-vulkan-drivers vulkan-tools"
                    ;;
                "dnf") 
                    install_package "xorg-x11-drv-amdgpu mesa-vulkan-drivers vulkan-tools"
                    ;;
                "pacman"|"yay") 
                    install_package "xf86-video-amdgpu mesa vulkan-radeon vulkan-tools"
                    ;;
                "zypper") 
                    install_package "xf86-video-amdgpu Mesa-dri vulkan-tools"
                    ;;
                *) echo_error "Unsupported package manager for AMD drivers"; return 1 ;;
            esac
            ;;
        "intel")
            case "$PACKAGE_MANAGER" in
                "apt") 
                    install_package "xserver-xorg-video-intel intel-media-va-driver vulkan-tools"
                    ;;
                "dnf") 
                    install_package "xorg-x11-drv-intel intel-media-driver vulkan-tools"
                    ;;
                "pacman"|"yay") 
                    install_package "xf86-video-intel intel-media-driver vulkan-intel"
                    ;;
                "zypper") 
                    install_package "xf86-video-intel intel-media-driver"
                    ;;
                *) echo_error "Unsupported package manager for Intel drivers"; return 1 ;;
            esac
            ;;
        "mesa")
            case "$PACKAGE_MANAGER" in
                "apt") 
                    install_package "mesa-utils mesa-vulkan-drivers libegl1-mesa libgl1-mesa-dri"
                    ;;
                "dnf") 
                    install_package "mesa-dri-drivers mesa-vulkan-drivers mesa-libGL"
                    ;;
                "pacman"|"yay") 
                    install_package "mesa mesa-utils vulkan-mesa-layers"
                    ;;
                "zypper") 
                    install_package "Mesa Mesa-libGL1 Mesa-dri"
                    ;;
                *) echo_error "Unsupported package manager for Mesa drivers"; return 1 ;;
            esac
            ;;
        "vulkan")
            case "$PACKAGE_MANAGER" in
                "apt") 
                    install_package "vulkan-tools vulkan-validationlayers mesa-vulkan-drivers"
                    ;;
                "dnf") 
                    install_package "vulkan-tools vulkan-validation-layers mesa-vulkan-drivers"
                    ;;
                "pacman"|"yay") 
                    install_package "vulkan-tools vulkan-validation-layers"
                    ;;
                "zypper") 
                    install_package "vulkan-tools vulkan-validationlayers"
                    ;;
                *) echo_error "Unsupported package manager for Vulkan"; return 1 ;;
            esac
            ;;
        "lib32")
            case "$PACKAGE_MANAGER" in
                "apt") 
                    install_package "mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386"
                    ;;
                "dnf") 
                    install_package "mesa-dri-drivers.i686 mesa-vulkan-drivers.i686"
                    ;;
                "pacman"|"yay") 
                    install_package "lib32-mesa lib32-vulkan-intel lib32-vulkan-radeon lib32-nvidia-utils"
                    ;;
                "zypper") 
                    install_package "Mesa-32bit Mesa-libGL1-32bit"
                    ;;
                *) echo_error "Unsupported package manager for 32-bit libraries"; return 1 ;;
            esac
            ;;
        *)
            echo_error "Unknown driver type: $driver_type"
            return 1
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo_success "Successfully installed $driver_type drivers"
        log_action "INSTALL_SUCCESS" "$driver_type-drivers"
    else
        echo_error "Failed to install $driver_type drivers"
        log_action "INSTALL_FAILED" "$driver_type-drivers"
    fi
}

#==============================================================================
# ADVANCED UNINSTALLER
#==============================================================================

# Define risky/important applications that require special warnings
declare -A RISKY_APPS=(
    ["bash"]="CRITICAL! System shell - removing this will break your system"
    ["sudo"]="CRITICAL! Administrative access - removing this will break system administration"
    ["systemd"]="CRITICAL! System initialization - removing this will break system boot"
    ["kernel"]="CRITICAL! System kernel - removing this will make system unbootable"
    ["libc"]="CRITICAL! Core library - removing this will break all applications"
    ["grub"]="CRITICAL! Boot loader - removing this will make system unbootable"
    ["ssh"]="IMPORTANT! Remote access - removing this will disable SSH access"
    ["network-manager"]="IMPORTANT! Network management - removing this may break network connectivity"
    ["pulseaudio"]="IMPORTANT! Audio system - removing this will disable audio"
    ["xorg"]="IMPORTANT! Display server - removing this will disable graphical interface"
    ["gnome-session"]="IMPORTANT! Desktop environment - removing this will disable desktop"
    ["kde-plasma"]="IMPORTANT! Desktop environment - removing this will disable desktop"
    ["firefox"]="RISK! Default browser - may be required by some applications"
    ["chromium"]="RISK! System browser - may be required by some applications"
    ["python3"]="RISK! System language - many applications depend on this"
    ["perl"]="RISK! System language - many system scripts depend on this"
    ["git"]="RISK! Version control - may be required for development tools"
    ["curl"]="RISK! Network tool - many applications depend on this"
    ["wget"]="RISK! Network tool - many applications depend on this"
    ["ca-certificates"]="RISK! SSL certificates - removing this will break HTTPS connections"
    ["gpg"]="RISK! Cryptographic tool - required for package verification"
    ["apt"]="CRITICAL! Package manager - removing this will break package management"
    ["dpkg"]="CRITICAL! Package installer - removing this will break package management"
    ["rpm"]="CRITICAL! Package manager - removing this will break package management"
    ["yum"]="CRITICAL! Package manager - removing this will break package management"
    ["dnf"]="CRITICAL! Package manager - removing this will break package management"
    ["pacman"]="CRITICAL! Package manager - removing this will break package management"
    ["zypper"]="CRITICAL! Package manager - removing this will break package management"
)

# Main uninstaller menu
show_uninstaller_menu() {
    clear
    show_header "ADVANCED UNINSTALLER"
    
    echo_menu_item "1" "Interactive Package Removal"
    echo_menu_item "2" "List Installed Packages"
    echo_menu_item "3" "Remove Package Dependencies"
    echo_menu_item "4" "Clean Package Cache"
    echo_menu_item "5" "Remove Orphaned Packages"
    echo_menu_item "0" "Back"
    echo
    read -p "Enter your choice [0-5]: " uninstall_choice
    
    case $uninstall_choice in
        1) interactive_package_removal ;;
        2) list_installed_packages ;;
        3) remove_package_dependencies ;;
        4) clean_package_cache ;;
        5) remove_orphaned_packages ;;
        0|back|Back) show_main_menu ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; show_uninstaller_menu ;;
    esac
}

# Interactive package removal with safety checks
interactive_package_removal() {
    clear
    show_header "INTERACTIVE PACKAGE REMOVAL"
    
    echo_info "Enter package name to remove (or 'list' to see installed packages):"
    read -p "Package name: " package_name
    
    if [[ "$package_name" == "list" ]]; then
        list_installed_packages
        return
    fi
    
    if [[ -z "$package_name" ]]; then
        echo_error "No package name provided."
        sleep 2
        show_uninstaller_menu
        return
    fi
    
    # Safety check for risky packages
    if [[ -n "${RISKY_APPS[$package_name]}" ]]; then
        echo_warning "WARNING: ${RISKY_APPS[$package_name]}"
        echo
        echo -n "Are you absolutely sure you want to continue? Type 'CONFIRM' to proceed: "
        read -r confirmation
        if [[ "$confirmation" != "CONFIRM" ]]; then
            echo_info "Operation cancelled for safety."
            sleep 2
            show_uninstaller_menu
            return
        fi
    fi
    
    # Check if package is installed
    if ! check_package_installed "$package_name"; then
        echo_error "Package '$package_name' is not installed."
        log_action "NOT_INSTALLED" "$package_name"
        sleep 2
        show_uninstaller_menu
        return
    fi
    
    # Show package dependencies that will be affected
    echo_info "Checking dependencies..."
    show_package_dependencies "$package_name"
    
    echo
    echo -n "Proceed with removal? [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo_progress "Removing $package_name..."
            if remove_package_safe "$package_name"; then
                echo_success "Successfully removed $package_name"
                log_action "UNINSTALL_SUCCESS" "$package_name"
            else
                echo_error "Failed to remove $package_name"
                log_action "UNINSTALL_FAILED" "$package_name"
            fi
            ;;
        *)
            echo_info "Operation cancelled."
            ;;
    esac
    
    sleep 2
    show_uninstaller_menu
}

# Show package dependencies
show_package_dependencies() {
    local package_name="$1"
    
    case "$PACKAGE_MANAGER" in
        "apt")
            echo_info "Packages that depend on $package_name:"
            apt-cache rdepends "$package_name" 2>/dev/null | head -10 || echo_info "No reverse dependencies found"
            ;;
        "dnf")
            echo_info "Packages that depend on $package_name:"
            dnf repoquery --whatrequires "$package_name" 2>/dev/null | head -10 || echo_info "No reverse dependencies found"
            ;;
        "pacman"|"yay")
            echo_info "Packages that depend on $package_name:"
            pacman -Qi "$package_name" 2>/dev/null | grep "Required By" || echo_info "No reverse dependencies found"
            ;;
        "zypper")
            echo_info "Packages that depend on $package_name:"
            zypper search --requires "$package_name" 2>/dev/null | head -10 || echo_info "No reverse dependencies found"
            ;;
    esac
}

# Safe package removal with dependency handling
remove_package_safe() {
    local package_name="$1"
    
    case "$PACKAGE_MANAGER" in
        "apt") 
            sudo apt remove --auto-remove -y "$package_name"
            ;;
        "dnf"|"yum") 
            sudo "$PACKAGE_MANAGER" remove -y "$package_name"
            ;;
        "pacman"|"yay") 
            sudo pacman -Rs --noconfirm "$package_name"
            ;;
        "zypper") 
            sudo zypper remove -y "$package_name"
            ;;
        *)
            echo_error "Unsupported package manager for safe removal"
            return 1
            ;;
    esac
}

# List installed packages
list_installed_packages() {
    clear
    show_header "INSTALLED PACKAGES"
    
    echo_info "Listing installed packages (first 50)..."
    echo
    
    case "$PACKAGE_MANAGER" in
        "apt")
            dpkg -l | grep "^ii" | awk '{print $2}' | head -50
            ;;
        "dnf"|"yum")
            "$PACKAGE_MANAGER" list installed | head -50
            ;;
        "pacman"|"yay")
            pacman -Q | head -50
            ;;
        "zypper")
            zypper search -i | head -50
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
    show_uninstaller_menu
}

# Remove package dependencies
remove_package_dependencies() {
    clear
    show_header "REMOVE PACKAGE DEPENDENCIES"
    
    echo_info "Enter package name to remove with its dependencies:"
    read -p "Package name: " package_name
    
    if [[ -n "$package_name" ]]; then
        echo_warning "This will remove $package_name and ALL its dependencies!"
        echo -n "Are you sure? [y/N]: "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY])
                case "$PACKAGE_MANAGER" in
                    "apt") 
                        sudo apt remove --auto-remove --purge -y "$package_name"
                        ;;
                    "dnf"|"yum") 
                        sudo "$PACKAGE_MANAGER" remove -y "$package_name"
                        sudo "$PACKAGE_MANAGER" autoremove -y
                        ;;
                    "pacman"|"yay") 
                        sudo pacman -Rscn --noconfirm "$package_name"
                        ;;
                    "zypper") 
                        sudo zypper remove --clean-deps -y "$package_name"
                        ;;
                esac
                echo_success "Package and dependencies removed!"
                ;;
            *)
                echo_info "Operation cancelled."
                ;;
        esac
    fi
    
    sleep 2
    show_uninstaller_menu
}

#==============================================================================
# SELECTION MENU SYSTEM
#==============================================================================

# Selection menu for install/actions
show_selection_menu() {
    local category="$1"; local title="$2"; shift 2; local items=("$@")
    
    while true; do
        clear
        show_header "$title"
        
        echo_info "Select items to $category by typing numbers (toggle)"
        echo_info "Type 'go' to proceed with $category"
        echo
        
        for i in "${!items[@]}"; do
            local item="${items[i]}"; local number=$((i + 1)); local status=""
            for sel in "${SELECTED_ITEMS[@]}"; do
                [[ "$sel" == "$item" ]] && status="${GREEN}[SELECTED]${NC}" && break
            done
            echo_menu_item "$number" "$item" "$status"
        done
        
        echo_menu_item "0" "Back"
        echo
        
        if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
            echo_info "Selected for $category (${#SELECTED_ITEMS[@]}):"
            for item in "${SELECTED_ITEMS[@]}"; do echo -e "  ${GREEN}•${NC} $item"; done
        else
            echo_info "No items selected for $category"
        fi
        echo
        
        read -p "Enter your selection: " selection
        
        case "${selection,,}" in
            "go")
                if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
                    confirm_and_run_action "$category"
                    return
                else
                    echo_error "No items selected!"; sleep 1
                fi
                ;;
            "back"|"0")
                SELECTED_ITEMS=()
                show_main_menu
                return
                ;;
            *)
                IFS=' ' read -ra SELECTIONS <<< "$selection"
                for sel in "${SELECTIONS[@]}"; do
                    if [[ "$sel" =~ ^[0-9]+$ ]] && [[ $sel -ge 0 && $sel -le ${#items[@]} ]]; then
                        if [[ $sel -eq 0 ]]; then 
                            SELECTED_ITEMS=()
                            show_main_menu
                            return
                        else
                            local item="${items[$((sel-1))]}"
                            local found=false
                            for s in "${SELECTED_ITEMS[@]}"; do 
                                [[ "$s" == "$item" ]] && found=true && break
                            done
                            if [[ "$found" == false ]]; then 
                                SELECTED_ITEMS+=("$item")
                            else
                                local tmp=()
                                for s in "${SELECTED_ITEMS[@]}"; do 
                                    [[ "$s" != "$item" ]] && tmp+=("$s")
                                done
                                SELECTED_ITEMS=("${tmp[@]}")
                            fi
                        fi
                    else
                        echo_error "Invalid selection: $sel"; sleep 1
                    fi
                done
                ;;
        esac
    done
}

# Confirm and run action
confirm_and_run_action() {
    local action="$1"
    
    if ! confirm_installation "$action" "${SELECTED_ITEMS[@]}"; then
        echo_info "Operation cancelled by user."
        sleep 1
        return
    fi
    
    echo_progress "Processing ${#SELECTED_ITEMS[@]} item(s)..."
    
    case "$action" in
        "Install"|"install")
            for item in "${SELECTED_ITEMS[@]}"; do
                install_app_by_name "$item"
            done
            ;;
        "Uninstall"|"uninstall")
            for item in "${SELECTED_ITEMS[@]}"; do
                uninstall_app_by_name "$item"
            done
            ;;
        *)
            echo_error "Unknown action: $action"
            ;;
    esac
    
    SELECTED_ITEMS=()
    echo_success "Operation completed!"
    sleep 2
    show_main_menu
}

# Uninstall selection menu
show_uninstall_selection_menu() {
    local category="$1"; local title="$2"; shift 2; local items=("$@")
    
    while true; do
        clear
        show_header "$title"
        
        echo_info "Select items to uninstall by typing numbers (toggle)"
        echo_info "Type 'go' to proceed"
        echo
        
        for i in "${!items[@]}"; do
            local item="${items[i]}"; local number=$((i + 1)); local status=""
            for sel in "${UNINSTALL_SELECTED_ITEMS[@]}"; do
                [[ "$sel" == "$item" ]] && status="${RED}[SELECTED]${NC}" && break
            done
            echo_menu_item "$number" "$item" "$status"
        done
        
        echo_menu_item "0" "Back"
        echo
        
        if [[ ${#UNINSTALL_SELECTED_ITEMS[@]} -gt 0 ]]; then
            echo_info "Selected for uninstall (${#UNINSTALL_SELECTED_ITEMS[@]}):"
            for item in "${UNINSTALL_SELECTED_ITEMS[@]}"; do echo -e "  ${RED}•${NC} $item"; done
        else
            echo_info "No items selected for uninstall"
        fi
        echo
        
        read -p "Enter your selection: " selection
        
        case "${selection,,}" in
            "go")
                if [[ ${#UNINSTALL_SELECTED_ITEMS[@]} -gt 0 ]]; then
                    uninstall_confirm_and_run
                    return
                else
                    echo_error "No items selected!"; sleep 1
                fi
                ;;
            "back"|"0")
                UNINSTALL_SELECTED_ITEMS=()
                show_main_menu
                return
                ;;
            *)
                IFS=' ' read -ra SELECTIONS <<< "$selection"
                for sel in "${SELECTIONS[@]}"; do
                    if [[ "$sel" =~ ^[0-9]+$ ]] && [[ $sel -ge 0 && $sel -le ${#items[@]} ]]; then
                        if [[ $sel -eq 0 ]]; then 
                            UNINSTALL_SELECTED_ITEMS=(); show_main_menu; return
                        else
                            local item="${items[$((sel-1))]}"
                            local found=false
                            for s in "${UNINSTALL_SELECTED_ITEMS[@]}"; do 
                                [[ "$s" == "$item" ]] && found=true && break
                            done
                            if [[ "$found" == false ]]; then 
                                UNINSTALL_SELECTED_ITEMS+=("$item")
                            else
                                local tmp=()
                                for s in "${UNINSTALL_SELECTED_ITEMS[@]}"; do 
                                    [[ "$s" != "$item" ]] && tmp+=("$s")
                                done
                                UNINSTALL_SELECTED_ITEMS=("${tmp[@]}")
                            fi
                        fi
                    else
                        echo_error "Invalid selection: $sel"; sleep 1
                    fi
                done
                ;;
        esac
    done
}

# Uninstall confirmation and run
uninstall_confirm_and_run() {
    clear
    show_ascii_logo
    show_header "UNINSTALL CONFIRMATION"
    
    echo_info "You are about to uninstall the following items:"
    for item in "${UNINSTALL_SELECTED_ITEMS[@]}"; do echo -e "  ${RED}•${NC} $item"; done
    
    echo_info "Package Manager: $PACKAGE_MANAGER"
    echo_info "Total Items: ${#UNINSTALL_SELECTED_ITEMS[@]}"
    
    echo -en "${YELLOW}${BOLD}Are you sure you want to uninstall the following items? [y/N]:${NC} "
    read -r response
    
    if [[ ! "$response" =~ ^[yY] ]]; then
        echo_info "Uninstall cancelled."; sleep 1; UNINSTALL_SELECTED_ITEMS=(); show_uninstaller_menu; return
    fi
    
    uninstall_run_action
    
    echo -en "${YELLOW}${BOLD}Do you want to clean up all leftover configs and dependencies? [y/N]:${NC} "
    read -r cleanup
    
    uninstall_log_cleanup="Skipped"
    if [[ "$cleanup" =~ ^[yY] ]]; then
        uninstall_run_cleanup
        uninstall_log_cleanup="Performed"
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S'): [UNINSTALL] Items: ${UNINSTALL_SELECTED_ITEMS[*]} | Cleanup: $uninstall_log_cleanup" >> "$UNINSTALL_LOG_FILE"
    UNINSTALL_SELECTED_ITEMS=()
    show_uninstaller_menu
}

# Run uninstall action
uninstall_run_action() {
    local success_count=0
    local failure_count=0
    
    for item in "${UNINSTALL_SELECTED_ITEMS[@]}"; do
        local pkg_name=$(get_package_name "$item")
        
        # Check if package is installed
        if ! check_package_installed "$pkg_name"; then
            echo_warning "$item is not installed"
            echo "[WARNING] $item ($pkg_name) is not installed" >> "$UNINSTALL_LOG_FILE"
            ((success_count++))
            continue
        fi
        
        echo_progress "Uninstalling $item ($pkg_name)..."
        case "$PACKAGE_MANAGER" in
            "apt") 
                if sudo apt remove -y $pkg_name; then
                    echo_success "Successfully uninstalled $item"
                    echo "[APT] Successfully uninstalled $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((success_count++))
                else
                    echo_error "Failed to uninstall $item"
                    echo "[APT] Failed to uninstall $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((failure_count++))
                fi
                ;;
            "dnf") 
                if sudo dnf remove -y $pkg_name; then
                    echo_success "Successfully uninstalled $item"
                    echo "[DNF] Successfully uninstalled $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((success_count++))
                else
                    echo_error "Failed to uninstall $item"
                    echo "[DNF] Failed to uninstall $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((failure_count++))
                fi
                ;;
            "yum") 
                if sudo yum remove -y $pkg_name; then
                    echo_success "Successfully uninstalled $item"
                    echo "[YUM] Successfully uninstalled $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((success_count++))
                else
                    echo_error "Failed to uninstall $item"
                    echo "[YUM] Failed to uninstall $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((failure_count++))
                fi
                ;;
            "pacman"|"yay") 
                if yay -R --noconfirm $pkg_name; then
                    echo_success "Successfully uninstalled $item"
                    echo "[YAY] Successfully uninstalled $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((success_count++))
                else
                    echo_error "Failed to uninstall $item"
                    echo "[YAY] Failed to uninstall $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((failure_count++))
                fi
                ;;
            "zypper") 
                if sudo zypper remove -y $pkg_name; then
                    echo_success "Successfully uninstalled $item"
                    echo "[ZYPPER] Successfully uninstalled $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((success_count++))
                else
                    echo_error "Failed to uninstall $item"
                    echo "[ZYPPER] Failed to uninstall $pkg_name" >> "$UNINSTALL_LOG_FILE"
                    ((failure_count++))
                fi
                ;;
            *) 
                echo_error "Unknown package manager: $PACKAGE_MANAGER"
                echo "[ERROR] Unknown PM: $PACKAGE_MANAGER $pkg_name" >> "$UNINSTALL_LOG_FILE"
                ((failure_count++))
                ;;
        esac
    done
    
    # Show summary
    echo
    echo_info "=== UNINSTALL SUMMARY ==="
    echo_success "Successful operations: $success_count"
    if [[ $failure_count -gt 0 ]]; then
        echo_error "Failed operations: $failure_count"
    fi
    echo_info "Check logs at: $UNINSTALL_LOG_FILE"
}

# Run cleanup after uninstall
uninstall_run_cleanup() {
    echo_progress "Running cleanup operations..."
    case "$PACKAGE_MANAGER" in
        "apt") 
            if sudo apt autoremove -y && sudo apt autoclean; then
                echo_success "APT cleanup completed successfully"
                echo "[APT] Cleanup completed successfully" >> "$UNINSTALL_LOG_FILE"
            else
                echo_error "APT cleanup failed"
                echo "[APT] Cleanup failed" >> "$UNINSTALL_LOG_FILE"
            fi
            ;;
        "dnf") 
            if sudo dnf autoremove -y && sudo dnf clean all; then
                echo_success "DNF cleanup completed successfully"
                echo "[DNF] Cleanup completed successfully" >> "$UNINSTALL_LOG_FILE"
            else
                echo_error "DNF cleanup failed"
                echo "[DNF] Cleanup failed" >> "$UNINSTALL_LOG_FILE"
            fi
            ;;
        "yum") 
            if sudo yum autoremove -y && sudo yum clean all; then
                echo_success "YUM cleanup completed successfully"
                echo "[YUM] Cleanup completed successfully" >> "$UNINSTALL_LOG_FILE"
            else
                echo_error "YUM cleanup failed"
                echo "[YUM] Cleanup failed" >> "$UNINSTALL_LOG_FILE"
            fi
            ;;
        "pacman"|"yay") 
            if yay -Sc --noconfirm && yay -Qtdq | yay -Rns --noconfirm -; then
                echo_success "Pacman/Yay cleanup completed successfully"
                echo "[YAY] Cleanup completed successfully" >> "$UNINSTALL_LOG_FILE"
            else
                echo_warning "Pacman/Yay cleanup partially completed"
                echo "[YAY] Cleanup partially completed" >> "$UNINSTALL_LOG_FILE"
            fi
            ;;
        "zypper") 
            if sudo zypper clean -a; then
                echo_success "Zypper cleanup completed successfully"
                echo "[ZYPPER] Cleanup completed successfully" >> "$UNINSTALL_LOG_FILE"
            else
                echo_error "Zypper cleanup failed"
                echo "[ZYPPER] Cleanup failed" >> "$UNINSTALL_LOG_FILE"
            fi
            ;;
        *) echo_error "Unknown package manager: $PACKAGE_MANAGER"; echo "[ERROR] Unknown PM: $PACKAGE_MANAGER (cleanup)" >> "$UNINSTALL_LOG_FILE" ;;
    esac
}

# Install app by name with proper package mapping
install_app_by_name() {
    local app_name="$1"
    local package_name=""
    
    # Map friendly names to actual package names
    case "${app_name,,}" in
        # Developer Tools
        "git") package_name="git" ;;
        "vim") package_name="vim" ;;
        "emacs") package_name="emacs" ;;
        "nano") package_name="nano" ;;
        "code"|"visual studio code") 
            case "$PACKAGE_MANAGER" in
                "apt") package_name="code" ;;
                "dnf"|"yum") package_name="code" ;;
                "pacman"|"yay") package_name="visual-studio-code-bin" ;;
                "zypper") package_name="code" ;;
            esac
            ;;
        "docker") package_name="docker docker-compose" ;;
        "nodejs"|"node") package_name="nodejs npm" ;;
        "python") package_name="python3 python3-pip" ;;
        "curl") package_name="curl" ;;
        "wget") package_name="wget" ;;
        "htop") package_name="htop" ;;
        "tmux") package_name="tmux" ;;
        "screen") package_name="screen" ;;
        
        # Web Browsers
        "firefox") package_name="firefox" ;;
        "chromium") package_name="chromium-browser" ;;
        "google chrome"|"chrome")
            case "$PACKAGE_MANAGER" in
                "apt") package_name="google-chrome-stable" ;;
                "dnf"|"yum") package_name="google-chrome-stable" ;;
                "pacman"|"yay") package_name="google-chrome" ;;
                "zypper") package_name="google-chrome-stable" ;;
            esac
            ;;
        
        # Multimedia Tools
        "vlc") package_name="vlc" ;;
        "mpv") package_name="mpv" ;;
        "ffmpeg") package_name="ffmpeg" ;;
        "gimp") package_name="gimp" ;;
        "audacity") package_name="audacity" ;;
        "kdenlive") package_name="kdenlive" ;;
        "obs"|"obs studio") package_name="obs-studio" ;;
        
        # Communication Apps
        "thunderbird") package_name="thunderbird" ;;
        "discord") 
            case "$PACKAGE_MANAGER" in
                "apt") package_name="discord" ;;
                "dnf"|"yum") package_name="discord" ;;
                "pacman"|"yay") package_name="discord" ;;
                "zypper") package_name="discord" ;;
            esac
            ;;
        "telegram") package_name="telegram-desktop" ;;
        "signal") package_name="signal-desktop" ;;
        
        # System Tools
        "neofetch") package_name="neofetch" ;;
        "btop") package_name="btop" ;;
        "ncdu") package_name="ncdu" ;;
        "tree") package_name="tree" ;;
        "unzip") package_name="unzip" ;;
        "zip") package_name="zip" ;;
        "7zip"|"7z") package_name="p7zip-full" ;;
        
        # Productivity Apps
        "libreoffice") package_name="libreoffice" ;;
        "inkscape") package_name="inkscape" ;;
        "blender") package_name="blender" ;;
        "krita") package_name="krita" ;;
        
        # Audio Drivers
        "alsa utils") package_name="alsa-utils" ;;
        "pulseaudio") package_name="pulseaudio" ;;
        "pipewire") package_name="pipewire" ;;
        "jack audio") package_name="jack" ;;
        "pavucontrol") package_name="pavucontrol" ;;
        "alsamixer") package_name="alsa-utils" ;;
        
        # Default fallback - use the name as is
        *) package_name="$app_name" ;;
    esac
    
    if [[ -n "$package_name" ]]; then
        echo_progress "Installing $app_name ($package_name)..."
        if install_package "$package_name"; then
            echo_success "Successfully installed $app_name"
            log_action "INSTALL_SUCCESS" "$app_name"
        else
            echo_error "Failed to install $app_name"
            log_action "INSTALL_FAILED" "$app_name"
        fi
    else
        echo_error "Unknown package: $app_name"
        log_action "INSTALL_FAILED" "$app_name"
    fi
    
    sleep 1
}

# Uninstall app by name
uninstall_app_by_name() {
    local app_name="$1"
    local package_name=""
    
    # Use same mapping as install
    case "${app_name,,}" in
        "git") package_name="git" ;;
        "vim") package_name="vim" ;;
        "firefox") package_name="firefox" ;;
        "vlc") package_name="vlc" ;;
        "htop") package_name="htop" ;;
        # Add more mappings as needed
        *) package_name="$app_name" ;;
    esac
    
    if [[ -n "$package_name" ]]; then
        echo_progress "Uninstalling $app_name ($package_name)..."
        case "$PACKAGE_MANAGER" in
            "apt") 
                if sudo apt remove -y "$package_name"; then
                    echo_success "Successfully uninstalled $app_name"
                    log_action "UNINSTALL_SUCCESS" "$app_name"
                else
                    echo_error "Failed to uninstall $app_name"
                    log_action "UNINSTALL_FAILED" "$app_name"
                fi
                ;;
            "dnf"|"yum") 
                if sudo "$PACKAGE_MANAGER" remove -y "$package_name"; then
                    echo_success "Successfully uninstalled $app_name"
                    log_action "UNINSTALL_SUCCESS" "$app_name"
                else
                    echo_error "Failed to uninstall $app_name"
                    log_action "UNINSTALL_FAILED" "$app_name"
                fi
                ;;
            "pacman"|"yay") 
                if sudo pacman -R --noconfirm "$package_name"; then
                    echo_success "Successfully uninstalled $app_name"
                    log_action "UNINSTALL_SUCCESS" "$app_name"
                else
                    echo_error "Failed to uninstall $app_name"
                    log_action "UNINSTALL_FAILED" "$app_name"
                fi
                ;;
            "zypper") 
                if sudo zypper remove -y "$package_name"; then
                    echo_success "Successfully uninstalled $app_name"
                    log_action "UNINSTALL_SUCCESS" "$app_name"
                else
                    echo_error "Failed to uninstall $app_name"
                    log_action "UNINSTALL_FAILED" "$app_name"
                fi
                ;;
        esac
    else
        echo_error "Unknown package: $app_name"
        log_action "UNINSTALL_FAILED" "$app_name"
    fi
    
    sleep 1
}

#==============================================================================
# SYSTEM UTILITIES
#==============================================================================

update_system() {
    clear
    show_header "UPDATING SYSTEM"
    
    echo_progress "Updating package database and system..."
    
    case "$PACKAGE_MANAGER" in
        "apt") 
            sudo apt update && sudo apt upgrade -y
            ;;
        "dnf") 
            sudo dnf update -y
            ;;
        "yum") 
            sudo yum update -y
            ;;
        "pacman") 
            sudo pacman -Syu --noconfirm
            ;;
        "yay") 
            yay -Syu --noconfirm
            ;;
        "zypper") 
            sudo zypper update -y
            ;;
    esac
    
    echo_success "System update complete!"
    sleep 3
    show_main_menu
}

clean_package_cache() {
    clear
    show_header "CLEANING PACKAGE CACHE"
    
    echo_progress "Cleaning package cache..."
    
    case "$PACKAGE_MANAGER" in
        "apt") 
            sudo apt autoremove -y && sudo apt autoclean
            ;;
        "dnf"|"yum") 
            sudo "$PACKAGE_MANAGER" autoremove -y && sudo "$PACKAGE_MANAGER" clean all
            ;;
        "pacman") 
            sudo pacman -Sc --noconfirm
            ;;
        "yay") 
            yay -Sc --noconfirm
            ;;
        "zypper") 
            sudo zypper clean -a
            ;;
    esac
    
    echo_success "Package cache cleaned!"
    sleep 2
    show_main_menu
}

show_system_info() {
    clear
    show_header "SYSTEM INFORMATION"
    
    echo_info "System Information:"
    echo "===================="
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Distribution: $(get_distro_name)"
    echo "Package Manager: $PACKAGE_MANAGER"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "Memory: $(free -h | grep Mem: | awk '{print $3 "/" $2}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')"
    echo
    
    read -p "Press Enter to continue..."
    show_main_menu
}

check_disk_usage() {
    clear
    show_header "DISK USAGE"
    
    echo_info "Disk Usage Information:"
    echo "======================="
    df -h
    echo
    
    read -p "Press Enter to continue..."
    show_main_menu
}

#==============================================================================
# MAIN EXECUTION
#==============================================================================

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
    echo -e "${BOLD}Kernel Runtime Operations for Linux - Standalone Version${NC}"
    echo
    
    sleep 2
}

# Auto-setup Git and clone KRONUX repository
setup_kronux_repository() {
    echo_info "Setting up KRONUX repository..."
    
    # Check if Git is installed, if not install it
    if ! command -v git >/dev/null 2>&1; then
        echo_progress "Git not found. Installing Git..."
        
        # Detect package manager if not already done
        if [[ -z "$PACKAGE_MANAGER" ]]; then
            PACKAGE_MANAGER=$(detect_package_manager)
        fi
        
        case "$PACKAGE_MANAGER" in
            "apt") sudo apt update && sudo apt install -y git ;;
            "dnf") sudo dnf install -y git ;;
            "yum") sudo yum install -y git ;;
            "pacman") sudo pacman -S --noconfirm git ;;
            "yay") yay -S --noconfirm git ;;
            "zypper") sudo zypper install -y git ;;
            *)
                echo_warning "Could not detect package manager. Please install Git manually."
                echo_info "Continuing without repository clone..."
                return 1
                ;;
        esac
        
        if command -v git >/dev/null 2>&1; then
            echo_success "Git installed successfully!"
        else
            echo_error "Failed to install Git. Continuing without repository clone..."
            return 1
        fi
    else
        echo_success "Git is already installed."
    fi
    
    # Set up repository directory
    local home_dir="$HOME"
    local repo_parent_dir="$home_dir/Documents"
    
    # Create Documents directory if it doesn't exist, fallback to home if needed
    if ! mkdir -p "$repo_parent_dir" 2>/dev/null; then
        repo_parent_dir="$home_dir"
        if ! mkdir -p "$repo_parent_dir" 2>/dev/null; then
            repo_parent_dir="/tmp"
            echo_warning "Using temporary directory for repository: /tmp"
        fi
    fi
    
    KRONUX_REPO_DIR="$repo_parent_dir/kronux"
    
    # Check if repository already exists
    if [[ -d "$KRONUX_REPO_DIR" ]]; then
        echo_info "KRONUX repository already exists at: $KRONUX_REPO_DIR"
        
        # Check if it's a git repository
        if [[ -d "$KRONUX_REPO_DIR/.git" ]]; then
            echo_progress "Checking repository status..."
            cd "$KRONUX_REPO_DIR"
            
            # Check if there are uncommitted changes
            if git status --porcelain 2>/dev/null | grep -q .; then
                echo_warning "Repository has local changes. Skipping update to preserve your work."
                echo_info "Repository location: $KRONUX_REPO_DIR"
            else
                echo_progress "Updating repository..."
                if git pull origin main 2>/dev/null; then
                    echo_success "Repository updated successfully!"
                else
                    echo_warning "Failed to update repository. You may need to update manually."
                fi
            fi
            cd - >/dev/null
        else
            echo_warning "Directory exists but is not a git repository."
            echo_info "Repository location: $KRONUX_REPO_DIR"
        fi
    else
        echo_progress "Cloning KRONUX repository..."
        
        if git clone "$KRONUX_REPO_URL" "$KRONUX_REPO_DIR" 2>/dev/null; then
            echo_success "KRONUX repository cloned successfully!"
            echo_info "Repository location: $KRONUX_REPO_DIR"
        else
            echo_error "Failed to clone repository. Check your internet connection."
            echo_info "You can manually clone it later with:"
            echo_info "git clone $KRONUX_REPO_URL"
            KRONUX_REPO_DIR=""
            return 1
        fi
    fi
    
    # Log the setup
    echo "$(date '+%Y-%m-%d %H:%M:%S'): [REPO_SETUP] Repository location: $KRONUX_REPO_DIR" >> "$LOG_FILE"
    
    sleep 1
    return 0
}

# Main function
main() {
    # Detect if running in non-interactive mode (via curl pipe)
    if [[ $NON_INTERACTIVE -eq 1 ]]; then
        # Non-interactive mode - provide information and exit gracefully
        show_ascii_logo
        echo_info "KRONUX - Linux Toolkit Successfully Downloaded!"
        echo
        echo_info "You are running KRONUX in non-interactive mode."
        echo_info "This typically happens when running via: curl -sL url | bash"
        echo
        echo_info "💡 To force interactive mode with curl | bash, use:"
        echo_info "  ${CYAN}curl -sL url | bash -s -- --interactive${NC}"
        echo
        
        # Initialize basic logging for non-interactive mode
        init_log
        
        # Set up repository even in non-interactive mode
        setup_kronux_repository
        
        echo
        echo_info "To use KRONUX interactively, run:"
        echo_info "  ${CYAN}bash kronux.sh${NC}"
        echo
        echo_info "Or navigate to the repository and explore:"
        if [[ -n "$KRONUX_REPO_DIR" && -d "$KRONUX_REPO_DIR" ]]; then
            echo_info "  ${CYAN}cd $KRONUX_REPO_DIR${NC}"
        else
            echo_info "  ${CYAN}cd /tmp/kronux-*${NC}"
        fi
        echo_info "  ${CYAN}ls -la${NC}"
        echo
        echo_info "Features available in interactive mode:"
        echo_info "  • 📦 Package management (install/uninstall)"
        echo_info "  • 🎮 Graphics driver installation"
        echo_info "  • ⚡ Hardware acceleration setup"
        echo_info "  • 🔧 System utilities and services"
        echo_info "  • 🗑️  Advanced uninstaller with dependency tracking"
        echo
        echo_info "Visit: ${BLUE}https://github.com/maulananais/kronux${NC}"
        echo_info "Documentation: ${BLUE}https://github.com/maulananais/kronux/blob/main/README.md${NC}"
        echo
        exit_toolkit
    fi
    
    # Interactive mode - full functionality
    # Show loading screen
    show_loading_screen
    
    # Initialize logging
    init_log
    
    # Setup KRONUX repository (install Git and clone repo)
    setup_kronux_repository
    
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

# Run main function when script is executed
# This handles direct execution, curl | bash, and all other scenarios
main "$@"
