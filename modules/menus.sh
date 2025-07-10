#!/bin/bash

# KRONUX Menu System
# Author: Maulana Nais
# Description: Menu system and navigation for KRONUX

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../modules/package_manager.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../modules/actions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../modules/uninstaller.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../modules/driver.sh"

# Main menu
show_main_menu() {
    clear
    show_header "MAIN MENU"
    
    echo_menu_item "1" "Install a Package"
    echo_menu_item "2" "Uninstall a Package"
    echo_menu_item "3" "Enable a Service"
    echo_menu_item "4" "Disable a Service"
    echo_menu_item "5" "App/Driver Modules"
    echo_menu_item "6" "Uninstall Modules"
    echo_menu_item "7" "Advanced Uninstaller"
    echo_menu_item "0" "Exit"
    echo
    read -p "Enter your choice [0-7]: " main_choice
    
    case $main_choice in
        1) push_nav show_install_package_menu; show_install_package_menu ;;
        2) push_nav show_uninstall_package_menu; show_uninstall_package_menu ;;
        3) push_nav show_enable_service_menu; show_enable_service_menu ;;
        4) push_nav show_disable_service_menu; show_disable_service_menu ;;
        5) push_nav show_module_menu; show_module_menu ;;
        6) push_nav show_uninstall_module_menu; show_uninstall_module_menu ;;
        7) push_nav show_uninstaller_menu; show_uninstaller_menu ;;
        0|back|Back|exit|Exit) exit_toolkit ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; show_main_menu ;;
    esac
}

# Quick package/service menus
show_install_package_menu() {
    clear
    show_header "INSTALL PACKAGE"
    show_selection_menu "Install" "INSTALL PACKAGE" "vim" "htop" "curl" "git" "tmux"
}

show_uninstall_package_menu() {
    clear
    show_header "UNINSTALL PACKAGE"
    show_selection_menu "Uninstall" "UNINSTALL PACKAGE" "vim" "htop" "curl" "git" "tmux"
}

show_enable_service_menu() {
    clear
    show_header "ENABLE SERVICE"
    show_selection_menu "Enable Service" "ENABLE SERVICE" "ssh" "cups" "bluetooth" "cron" "avahi-daemon"
}

show_disable_service_menu() {
    clear
    show_header "DISABLE SERVICE"
    show_selection_menu "Disable Service" "DISABLE SERVICE" "ssh" "cups" "bluetooth" "cron" "avahi-daemon"
}

# Module menu
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
        1) push_nav show_developer_tools; show_developer_tools ;;
        2) push_nav show_web_browsers; show_web_browsers ;;
        3) push_nav show_multimedia_tools; show_multimedia_tools ;;
        4) push_nav show_communication_apps; show_communication_apps ;;
        5) push_nav show_system_tools; show_system_tools ;;
        6) push_nav show_productivity_apps; show_productivity_apps ;;
        7) push_nav show_graphics_drivers; show_graphics_drivers ;;
        8) push_nav show_audio_drivers; show_audio_drivers ;;
        9) push_nav show_system_tweaks; show_system_tweaks ;;
        10) push_nav show_system_cleanup; show_system_cleanup ;;
        0|back|Back) pop_nav; ${NAV_STACK[-1]} ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; show_module_menu ;;
    esac
}

# Category menus
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

show_productivity_apps() {
    clear
    show_header "PRODUCTIVITY APPS"
    local items=("LibreOffice" "OnlyOffice" "Vim" "Emacs" "Nano" "Gedit" "Kate" "Sublime Text" "Atom" "Typora" "Obsidian" "Notion" "Evernote" "Simplenote" "Todoist" "Taskwarrior" "Calcurse" "Zettlr")
    show_selection_menu "Install" "PRODUCTIVITY APPS" "${items[@]}"
}

show_graphics_drivers() {
    clear
    show_header "GRAPHICS DRIVERS"

    # First check dependencies and hardware
    check_dependencies || {
        echo_error "Missing required dependencies. Please install them first."
        sleep 2
        return 1
    }

    detect_graphics_hardware || {
        echo_error "Failed to detect graphics hardware."
        sleep 2
        return 1
    }

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
                install_graphics_driver "nvidia" || {
                    echo_error "Failed to install NVIDIA drivers."
                    sleep 2
                }
            fi
            ;;
        2)
            if validate_hardware "amd"; then
                install_graphics_driver "amd" || {
                    echo_error "Failed to install AMD drivers."
                    sleep 2
                }
            fi
            ;;
        3)
            if validate_hardware "intel"; then
                install_graphics_driver "intel" || {
                    echo_error "Failed to install Intel drivers."
                    sleep 2
                }
            fi
            ;;
        4)
            install_graphics_driver "mesa" || {
                echo_error "Failed to install Mesa drivers."
                sleep 2
            }
            ;;
        5)
            install_graphics_driver "vulkan" || {
                echo_error "Failed to install Vulkan support."
                sleep 2
            }
            ;;
        6)
            install_graphics_driver "lib32" || {
                echo_error "Failed to install 32-bit graphics libraries."
                sleep 2
            }
            ;;
        7)
            push_nav show_hw_acceleration_menu
            show_hw_acceleration_menu
            return
            ;;
        0|back|Back)
            pop_nav
            ${NAV_STACK[-1]}
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

# Uninstall module menu
show_uninstall_module_menu() {
    clear
    show_header "UNINSTALL MODULE MENU"
    
    echo_menu_item "1" "Uninstall Installed Apps"
    echo_menu_item "2" "Uninstall Previously Applied Tweaks"
    echo_menu_item "3" "Uninstall Drivers"
    echo_menu_item "0" "Back"
    echo
    read -p "Enter your choice [0-3]: " uninstall_choice
    
    case $uninstall_choice in
        1) push_nav show_uninstall_apps_menu; show_uninstall_apps_menu ;;
        2) push_nav show_uninstall_tweaks_menu; show_uninstall_tweaks_menu ;;
        3) push_nav show_uninstall_drivers_menu; show_uninstall_drivers_menu ;;
        0|back|Back) pop_nav; ${NAV_STACK[-1]} ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; show_uninstall_module_menu ;;
    esac
}

# Uninstall category menus
show_uninstall_apps_menu() {
    clear
    show_header "UNINSTALL APPS"
    local items=("Visual Studio Code" "VSCodium" "Neovim" "Vim" "Git" "Node.js & NPM" "Python 3" "Python PIP" "Docker" "Docker Compose" "cURL" "Wget" "JQ" "GCC" "Make" "CMake" "Flatpak" "Snap" "Zsh" "Fish Shell")
    show_uninstall_selection_menu "Uninstall Apps" "UNINSTALL APPS" "${items[@]}"
}

show_uninstall_tweaks_menu() {
    clear
    show_header "UNINSTALL TWEAKS"
    local items=("Install TLP" "Configure Swappiness" "Enable ZRAM" "Optimize SSD" "CPU Governor" "Reduce GRUB Timeout" "Disable Snap" "Enable Flatpak" "GNOME Tweaks" "Configure Fonts" "UFW Firewall" "System Hardening")
    show_uninstall_selection_menu "Uninstall Tweaks" "UNINSTALL TWEAKS" "${items[@]}"
}

show_uninstall_drivers_menu() {
    clear
    show_header "UNINSTALL DRIVERS"
    local items=("NVIDIA Proprietary Drivers" "AMD/ATI Open Source Drivers" "Intel Graphics Drivers" "Mesa Drivers" "Vulkan Support" "32-bit Graphics Libraries")
    show_uninstall_selection_menu "Uninstall Drivers" "UNINSTALL DRIVERS" "${items[@]}"
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
                install_hw_acceleration "intel-new" || {
                    echo_error "Failed to install Intel Media Driver."
                    sleep 2
                }
            else
                echo_error "No Intel GPU detected."
                sleep 2
            fi
            ;;
        2)
            if [[ "$HAS_INTEL" == "1" ]]; then
                install_hw_acceleration "intel-old" || {
                    echo_error "Failed to install Intel VA Driver."
                    sleep 2
                }
            else
                echo_error "No Intel GPU detected."
                sleep 2
            fi
            ;;
        3)
            if [[ "$HAS_AMD" == "1" ]]; then
                install_hw_acceleration "amd" || {
                    echo_error "Failed to install AMD VA/VDPAU drivers."
                    sleep 2
                }
            else
                echo_error "No AMD GPU detected."
                sleep 2
            fi
            ;;
        4)
            if [[ "$HAS_NVIDIA" == "1" ]]; then
                install_hw_acceleration "nvidia-vaapi" || {
                    echo_error "Failed to install NVIDIA VAAPI bridge."
                    sleep 2
                }
            else
                echo_error "No NVIDIA GPU detected."
                sleep 2
            fi
            ;;
        5)
            # Install appropriate 32-bit acceleration based on GPU
            if [[ "$HAS_AMD" == "1" ]]; then
                install_hw_acceleration "amd-32bit" || {
                    echo_error "Failed to install 32-bit AMD acceleration."
                    sleep 2
                }
            fi
            if [[ "$HAS_NVIDIA" == "1" ]]; then
                install_hw_acceleration "nvidia-vaapi-32bit" || {
                    echo_error "Failed to install 32-bit NVIDIA acceleration."
                    sleep 2
                }
            fi
            ;;
        6)
            install_hw_acceleration "dvd" || {
                echo_error "Failed to install DVD playback support."
                sleep 2
            }
            ;;
        7)
            install_hw_acceleration "firmware" || {
                echo_error "Failed to install additional firmware."
                sleep 2
            }
            ;;
        0|back|Back)
            pop_nav
            ${NAV_STACK[-1]}
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
