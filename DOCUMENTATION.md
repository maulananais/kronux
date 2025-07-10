# KRONUX Documentation

<p align="center">
  <img src="assets/kronux.png" alt="KRONUX logo" width="200"/>
</p>

**Complete documentation for KRONUX - Kernel Runtime Operations for Linux**

---

## 📖 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [🎮 Usage Guide](#-usage-guide)
- [📦 Package Management](#-package-management)
- [🖥️ Graphics Drivers](#-graphics-drivers)
- [🔧 System Utilities](#-system-utilities)
- [🗑️ Advanced Uninstaller](#-advanced-uninstaller)
- [⚙️ Configuration](#-configuration)
- [🔍 Troubleshooting](#-troubleshooting)
- [📁 File Structure](#-file-structure)
- [🧩 Modules Overview](#-modules-overview)

---

## 🚀 Quick Start

### Installation Methods

**Method 1: Standalone Script (Recommended)**
```bash
curl -sL https://raw.githubusercontent.com/maulananais/kronux/main/kronux.sh > /tmp/kronux.sh && bash /tmp/kronux.sh
```

**Method 2: Git Clone (Development)**
```bash
git clone https://github.com/maulananais/kronux.git
cd kronux
chmod +x kronux.sh
./kronux.sh
```

**Method 3: Direct Download**
```bash
wget https://raw.githubusercontent.com/maulananais/kronux/main/kronux.sh
chmod +x kronux.sh
./kronux.sh
```

### First Run Experience

1. **Package Manager Detection**: KRONUX automatically detects your distribution and package manager
2. **Sudo Access Check**: Confirms you have administrative privileges
3. **Repository Setup**: Downloads and sets up the complete KRONUX repository
4. **Main Menu**: Presents the interactive menu system

---

## 🎮 Usage Guide

### Navigation System

- **Number Selection**: Type numbers to select menu items
- **Multiple Selection**: Space-separated numbers (e.g., `1 3 5`)
- **Toggle Selection**: Select/deselect items by typing their numbers
- **Execute**: Type `go` to proceed with selected items
- **Back Navigation**: Type `0`, `back`, or `Back` to return to previous menu
- **Exit**: Type `exit` or `Exit` from main menu

### Menu Structure

```
Main Menu
├── [1] Install a Package
├── [2] Uninstall a Package  
├── [3] Enable a Service
├── [4] Disable a Service
├── [5] App/Driver Modules
│   ├── Developer Tools
│   ├── Web Browsers
│   ├── Multimedia Tools
│   ├── Communication Apps
│   ├── System Tools
│   ├── Productivity Apps
│   ├── Graphics Drivers
│   ├── Audio Drivers
│   ├── System Tweaks
│   └── System Cleanup
├── [6] Graphics Drivers
├── [7] Advanced Uninstaller
├── [8] System Utilities
└── [0] Exit
```

---

## 📦 Package Management

### Supported Package Managers

| Distribution | Package Manager | Status |
|-------------|----------------|---------|
| Ubuntu/Debian | `apt` | ✅ Fully Supported |
| Fedora/RHEL | `dnf` | ✅ Fully Supported |
| CentOS/RHEL (Legacy) | `yum` | ✅ Fully Supported |
| Arch Linux | `pacman` | ✅ Fully Supported |
| Arch (AUR) | `yay` | ✅ Fully Supported |
| openSUSE | `zypper` | ✅ Fully Supported |

### Installation Categories

#### 🛠️ Developer Tools
- **Code Editors**: VS Code, VSCodium, Neovim, Vim, Nano
- **Version Control**: Git, GitHub CLI
- **Languages**: Node.js, Python 3, Go, Rust
- **Build Tools**: GCC, Make, CMake
- **Containers**: Docker, Docker Compose
- **Shell Tools**: Zsh, Fish Shell, Tmux, Screen

#### 🌐 Web Browsers
- **Modern Browsers**: Firefox, Chrome, Chromium, Brave
- **Privacy-Focused**: Tor Browser, Brave Browser
- **Alternative**: Opera, Vivaldi, Microsoft Edge
- **Text-Based**: Lynx, Links2

#### 🎵 Multimedia Tools
- **Video Players**: VLC, MPV, MPlayer
- **Video Editors**: Kdenlive, OpenShot, DaVinci Resolve
- **Audio Editors**: Audacity, Ardour
- **Graphics**: GIMP, Inkscape, Krita, Blender
- **Streaming**: OBS Studio
- **Converters**: FFmpeg, Handbrake

#### 💬 Communication Apps
- **Team Chat**: Discord, Slack, Microsoft Teams
- **Messaging**: Telegram, Signal, WhatsApp
- **Video Calls**: Zoom, Skype, Jitsi Meet
- **Email**: Thunderbird, Evolution
- **IRC/Matrix**: HexChat, Element, Weechat

#### 🏢 Productivity Apps
- **Office Suites**: LibreOffice, OnlyOffice
- **Note Taking**: Obsidian, Notion, Typora, Zettlr
- **Task Management**: Todoist, Taskwarrior
- **PDF Tools**: Okular, Evince, PDF Studio

### Package Name Mapping

KRONUX automatically maps friendly application names to distribution-specific package names:

```bash
# Example mappings
"Visual Studio Code" → 
  - apt: "code"
  - dnf: "code" 
  - pacman: "visual-studio-code-bin"
  - zypper: "code"

"Google Chrome" →
  - apt: "google-chrome-stable"
  - dnf: "google-chrome-stable"
  - pacman: "google-chrome"
  - zypper: "google-chrome-stable"
```

---

## 🖥️ Graphics Drivers

### Auto Hardware Detection

KRONUX automatically detects your graphics hardware:

- **Intel Graphics**: HD Graphics, Iris, Arc
- **NVIDIA Graphics**: GeForce, Quadro, Tesla
- **AMD Graphics**: Radeon, FirePro

### Driver Installation Options

#### NVIDIA Drivers
- **Proprietary**: Latest stable drivers from NVIDIA
- **Open Source**: Nouveau drivers (pre-installed)
- **CUDA Support**: Development toolkit for NVIDIA GPUs

#### AMD Drivers  
- **AMDGPU**: Modern open-source driver (recommended)
- **Radeon**: Legacy open-source driver
- **AMDGPU-PRO**: Proprietary driver for professional use

#### Intel Drivers
- **Mesa**: Open-source Intel graphics (recommended)
- **Intel Media Driver**: Hardware acceleration for newer GPUs
- **Legacy VA Driver**: For older Intel graphics

### Hardware Acceleration

#### Video Acceleration APIs
- **VA-API**: Video Acceleration API (Intel/AMD)
- **VDPAU**: Video Decode/Presentation API (NVIDIA/AMD)
- **NVENC/NVDEC**: NVIDIA hardware encoding/decoding

#### 32-bit Library Support
- Essential for Steam, Wine, and legacy applications
- Automatically installs compatibility libraries

---

## 🔧 System Utilities

### System Management
- **Update System**: Comprehensive system and package updates
- **Clean Package Cache**: Remove cached packages and orphaned files
- **System Information**: Hardware, kernel, and distribution details
- **Disk Usage**: Monitor storage utilization

### Service Management
- **Enable Services**: Start and enable systemd services
- **Disable Services**: Stop and disable systemd services
- **Service Status**: Check service health and logs

### System Tweaks
- **TLP Power Management**: Optimize laptop battery life
- **Swappiness Configuration**: Tune virtual memory behavior
- **ZRAM Setup**: Compressed RAM for better performance
- **SSD Optimization**: Enable TRIM and optimize for SSDs
- **CPU Governor**: Configure performance vs. power saving
- **GRUB Timeout**: Reduce boot loader wait time

---

## 🗑️ Advanced Uninstaller

### Safety Features

#### Risk Assessment
KRONUX categorizes packages by risk level:

- **🔴 CRITICAL**: System components that will break your system
- **🟡 IMPORTANT**: Components that may affect major functionality
- **🟠 RISK**: Packages that other applications depend on

#### Protected Packages
- **System Shells**: bash, zsh, fish
- **Package Managers**: apt, dnf, pacman, zypper
- **Core Libraries**: libc, systemd
- **Boot Components**: grub, kernel
- **Network**: NetworkManager, SSH

### Uninstall Options

#### Interactive Removal
- Single package removal with dependency checking
- Shows packages that depend on the target
- Confirmation prompts for safety

#### Batch Removal
- Select multiple packages for removal
- Dependency analysis for entire selection
- Optional cleanup of leftover configurations

#### Cleanup Operations
- Remove orphaned packages
- Clean configuration files
- Clear package caches
- Vacuum system logs

---

## ⚙️ Configuration

### Logging System

KRONUX maintains detailed logs:

```
logs/
├── install-log.txt    # Installation operations
└── uninstall-log.txt  # Removal operations
```

**Log Format:**
```
2025-07-11 10:30:25: [INSTALL_SUCCESS] firefox
2025-07-11 10:32:10: [UNINSTALL_SUCCESS] chromium
2025-07-11 10:33:45: [INSTALL_FAILED] non-existent-package
```

### Configuration Files

```
config/
└── config.sh         # System configuration
```

### Environment Variables

- `DEBUG=1`: Enable verbose debugging output
- `KRONUX_REPO_DIR`: Override repository location
- `NON_INTERACTIVE=1`: Force non-interactive mode

---

## 🔍 Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Ensure you have sudo privileges
sudo -v

# Check if user is in sudo group
groups $USER
```

#### Package Manager Issues
```bash
# Update package databases
sudo apt update          # Debian/Ubuntu
sudo dnf update          # Fedora
sudo pacman -Sy          # Arch Linux
sudo zypper refresh      # openSUSE
```

#### Network Issues
```bash
# Test connectivity
curl -I https://github.com

# Check DNS resolution  
nslookup github.com
```

#### Git Issues
```bash
# Check Git installation
git --version

# Configure Git (if needed)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Debug Mode

Enable detailed debugging:
```bash
DEBUG=1 bash kronux.sh
```

### Log Analysis

Check recent installations:
```bash
tail -20 logs/install-log.txt
```

Check recent removals:
```bash
tail -20 logs/uninstall-log.txt
```

---

## 📁 File Structure

```
kronux/
├── kronux.sh                    # Main standalone script
├── main.sh                      # Alternative entry point
├── README.md                    # Project overview
├── DOCUMENTATION.md             # This documentation
├── LICENSE                      # MIT license
├── assets/                      # Images and logos
│   ├── kronux.png
│   ├── kronux-ascii.png
│   ├── demo-main_menu.png
│   └── demo-select_pkg.png
├── config/
│   └── config.sh               # Configuration settings
├── docs/
│   └── ADVANCED_UNINSTALLER.md # Uninstaller documentation
├── lib/
│   └── utils.sh                # Utility functions
├── logs/                       # Operation logs
│   ├── install-log.txt
│   └── uninstall-log.txt
└── modules/                    # Feature modules
    ├── actions.sh              # Installation actions
    ├── driver.sh               # Graphics driver management
    ├── menus.sh                # Menu system
    ├── package_manager.sh      # Package manager abstraction
    └── uninstaller.sh          # Advanced uninstaller
```

---

## 🧩 Modules Overview

### Core Modules

#### `actions.sh`
- Package installation logic
- Application-specific installers
- Download and compilation routines

#### `driver.sh` 
- Hardware detection
- Graphics driver installation
- Hardware acceleration setup

#### `menus.sh`
- Interactive menu system
- Navigation logic
- User input handling

#### `package_manager.sh`
- Multi-distro package manager abstraction
- Package name mapping
- Installation/removal operations

#### `uninstaller.sh`
- Advanced package removal
- Dependency analysis
- Safety checks and warnings

### Utility Libraries

#### `lib/utils.sh`
- Common utility functions
- Logging mechanisms
- Display formatting

---

## 🤝 Contributing

### Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Test thoroughly
6. Submit a pull request

### Adding New Packages

1. Add package mapping in `get_package_name()` function
2. Update the appropriate module category
3. Test installation on multiple distributions
4. Update documentation

### Testing

Always test changes on multiple distributions:
- Ubuntu/Debian (apt)
- Fedora (dnf)
- Arch Linux (pacman)
- openSUSE (zypper)

---

## 📞 Support

- **GitHub Issues**: [Report bugs and request features](https://github.com/maulananais/kronux/issues)
- **Documentation**: This file and inline code comments
- **Repository**: [https://github.com/maulananais/kronux](https://github.com/maulananais/kronux)

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**KRONUX - Making Linux setup simple, powerful, and beautiful.** 🐧✨
