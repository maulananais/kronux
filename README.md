<p align="center">
  <img src="assets/kronux.png" alt="KRONUX logo" width="240"/>
</p>

# KRONUX — Kernel Runtime Operations for Linux

**A full-featured, modular Linux CLI system for installing, uninstalling, and tweaking your system with style and power.**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/language-bash-green.svg)]()
[![Version](https://img.shields.io/badge/version-2.0-orange.svg)]()
[![GitHub stars](https://img.shields.io/github/stars/maulananais/kronux?logo=github&style=flat)](https://github.com/maulananais/kronux/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/maulananais/kronux?logo=github&style=flat)](https://github.com/maulananais/kronux/issues)
[![Repository](https://img.shields.io/badge/repo-kronux-blue?logo=folder&style=flat)](https://github.com/maulananais/kronux)

## 🚀 Features

- **Modular Bash architecture** — Easy to extend and debug
- **CLI-first UX** — Dynamic selection, spinners, and logs
- **App installer & uninstaller** — Toggle packages by number selection
- **Graphics Driver Support** — Automatic hardware detection and driver installation
- **Hardware Acceleration** — Support for VA-API, VDPAU, and multimedia codecs
- **Clean terminal views** — Clear and focused menus
- **Logging enabled** — `logs/install-log.txt` and `logs/uninstall-log.txt` auto-created
- **Multi-distro support** — `apt`, `dnf`, `yay`, `zypper`
- **Fast back-navigation** — Via `[0] Back` or `back` keyword
- **Runs standalone** — Via `curl` or `git clone` style
- **Advanced uninstaller** — Risk assessment and smart filtering
- **Special package support** — Chrome, VSCode, Discord, Docker, etc.

## 📸 Screenshots / Demo

### ⏳ Loading Screen
![KRONUX Loading ASCII](assets/kronux-ascii.png)

### 🖱️ Package Selection
![Package Selection Demo](assets/demo-select_pkg.png)

### 🖼️ Main Menu
![Main Menu Demo](assets/demo-main_menu.png)

## 💻 Installation

### 🧩 Clone via Git
```bash
git clone https://github.com/maulananais/kronux.git
cd kronux
chmod +x main.sh
./main.sh
```

### ☁️ Run via curl (Experimental)
```bash
curl -sL https://raw.githubusercontent.com/maulananais/kronux/main/main.sh | bash
```
> ⚠️ **Note:** Some features like persistent logging may not be available unless the repo is cloned.

## 🔧 Requirements

- **Any modern Linux distro**
- **Bash v5+**
- **Supported package manager:**
  - `apt` / `dnf` / `yay` / `zypper`
- **sudo privileges**
- **(Optional)** `git` if you want to clone

## 💡 Why KRONUX?

**KRONUX was built to reduce Linux setup fatigue.**

Whether you're a distrohopper, sysadmin, or daily driver user — you deserve a fast, clean, and repeatable setup flow.

- ✅ **No fluff, no dependencies, no clutter**
- ✅ **Works offline** (once cloned)
- ✅ **Clean UI, structured logs, minimal design**
- ✅ **Just Bash** — nothing else

## 🛡️ Advanced Features

### **Graphics Driver Module**
- **Auto Hardware Detection** — Automatically detects Intel, NVIDIA, and AMD graphics hardware
- **Driver Installation** — Supports proprietary and open-source drivers for all major GPU vendors
- **Hardware Acceleration** — VA-API, VDPAU, and Intel Media Driver support
- **Multi-architecture Support** — 32-bit libraries for gaming and compatibility
- **Repository Setup** — Automatic configuration of required repositories (RPM Fusion, multilib, etc.)
- **Dependency Validation** — Ensures all required tools are available before installation
- **Post-install Guidance** — Clear instructions for system restart and configuration

### **Smart Uninstaller**
- **Automatic Detection** — Scans system for unused applications
- **Risk Assessment** — Categorizes applications by safety level
- **Smart Filtering** — Separates safe, risky, and critical applications
- **Multiple Modes** — Manual selection, clean uninstall, system scan

### **Special Package Support**
- **Google Chrome** — Official repository setup for all distributions
- **Microsoft Edge** — Official repository setup for all distributions
- **Brave Browser** — Official repository setup for all distributions
- **Visual Studio Code** — Official repository setup for all distributions
- **Discord** — Direct download with format detection
- **Docker** — Complete installation with user group setup
- **Flatpak** — Installation with Flathub repository configuration

### **Hardware Acceleration Support**
- **Intel GPUs** — Intel Media Driver (new) and VA Driver (legacy) support
- **AMD GPUs** — Mesa VA/VDPAU drivers with freeworld variants (Fedora)
- **NVIDIA GPUs** — VAAPI bridge for hardware acceleration
- **32-bit Support** — Gaming compatibility with Steam and Wine
- **DVD Playback** — libdvdcss installation for encrypted DVD support
- **Firmware Packages** — Additional hardware firmware for optimal compatibility

### **Risk Assessment System**
- **CRITICAL** 🚫 — System essential applications (bash, sudo, systemd)
- **IMPORTANT** ⚠️ — System functionality apps (network-manager, pulseaudio)
- **RISKY** ⚠️ — Dependencies many applications rely on (python3, curl, git)
- **SAFE** ✅ — Applications that can be removed safely

## 📁 Project Structure

```
├── main.sh                  # Main entry point
├── config/
│   └── config.sh           # Configuration and global variables
├── lib/
│   └── utils.sh            # Utility functions and common operations
├── modules/
│   ├── package_manager.sh  # Package manager detection and mapping
│   ├── actions.sh          # Action handlers (install, uninstall, services)
│   ├── menus.sh            # Menu system and navigation
│   ├── uninstaller.sh      # Advanced uninstaller functionality
│   └── driver.sh           # Graphics driver installation and hardware acceleration
├── logs/
│   ├── install-log.txt     # Installation logs
│   └── uninstall-log.txt   # Uninstallation logs
├── assets/                 # Images and visual assets
│   ├── kronux.png
│   ├── kronux-ascii.png
│   ├── demo-main_menu.png
│   └── demo-select_pkg.png
└── docs/
    └── ADVANCED_UNINSTALLER.md
```

## 🤝 Contributing

Feel free to fork, modify, or submit improvements.
PRs are welcome, especially for new modules or distros.

## 🧾 License

KRONUX is released under the **MIT License**.

## 📢 Connect & Support

<p align="center">
  <a href="https://instagram.com/mqulqnqq" target="_blank">
    <img src="https://img.shields.io/badge/Instagram-mqulqnqq-E4405F?logo=instagram&logoColor=white" alt="Instagram">
  </a>
  <a href="https://linkedin.com/in/maulananais" target="_blank">
    <img src="https://img.shields.io/badge/LinkedIn-maulananais-0A66C2?logo=linkedin&logoColor=white" alt="LinkedIn">
  </a>
  <a href="https://saweria.co/maulananais" target="_blank">
    <img src="https://img.shields.io/badge/Saweria-Donate-orange?logo=buymeacoffee&logoColor=white" alt="Saweria">
  </a>
</p>

❤️ **Found KRONUX useful?** Consider donating or sharing the project!

---

## ✨ Author

**Made with heart by Maulana Nais.**  
🐧 Linux Enthusiast. CLI Tweaker. Automation Addict.
