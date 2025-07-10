#!/bin/bash

# KRONUX Package Manager
# Author: Maulana Nais
# Description: Package manager selection and package name mapping

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

# Package manager selection menu
select_package_manager() {
    clear
    echo -e "${BOLD}Select your package manager:${NC}"
    echo
    echo_menu_item "1" "apt"
    echo_menu_item "2" "dnf"
    echo_menu_item "3" "yay"
    echo_menu_item "4" "zypper"
    echo_menu_item "0" "Exit"
    echo
    read -p "Enter your choice [0-4]: " pm_choice
    
    case $pm_choice in
        1) PACKAGE_MANAGER="apt"; push_nav show_main_menu; show_main_menu ;;
        2) PACKAGE_MANAGER="dnf"; push_nav show_main_menu; show_main_menu ;;
        3) PACKAGE_MANAGER="yay"; push_nav show_main_menu; show_main_menu ;;
        4) PACKAGE_MANAGER="zypper"; push_nav show_main_menu; show_main_menu ;;
        0|exit|Exit) exit_toolkit ;;
        *) echo_error "Invalid choice. Please try again."; sleep 1; select_package_manager ;;
    esac
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
                *) echo "${generic_name,,}" ;;
            esac 
            ;;
        *) echo "${generic_name,,}" ;;
    esac
}
