# Advanced Uninstaller Module Documentation

## Overview
The Advanced Uninstaller Module provides comprehensive application removal capabilities with intelligent risk assessment and automatic detection of unused applications.

## Features

### 1. Manual Selection Mode
- **Purpose**: Choose specific applications to uninstall
- **Features**:
  - Browse all installed applications
  - Toggle selection with numbers
  - Real-time risk assessment display
  - Confirmation with detailed warnings

### 2. Clean Uninstall Mode (Automatic Detection)
- **Purpose**: Automatically detect and remove unused applications
- **Features**:
  - Scans system for unused applications
  - Separates safe and risky applications
  - Three removal options:
    - Safe applications only (recommended)
    - Safe + risky applications (advanced users)
    - Custom selection from detected applications

### 3. System Scan Mode
- **Purpose**: Show all installed applications with risk assessment
- **Features**:
  - Categorizes applications by risk level:
    - **CRITICAL**: System essential (apt, bash, sudo, systemd, etc.)
    - **IMPORTANT**: System functionality (network-manager, pulseaudio, xorg)
    - **RISKY**: Dependencies (curl, git, python3, perl, etc.)
    - **SAFE**: Can be removed safely
  - Comprehensive system overview
  - No removal, information only

### 4. Category-based Uninstall
- **Purpose**: Remove applications by type
- **Categories**:
  - Development Tools
  - Web Browsers
  - Multimedia Applications
  - Games
  - Office Applications
  - System Utilities
  - Language Packages
  - Orphaned Packages

## Risk Assessment System

### Critical Applications (🚫)
Applications that are essential for system operation:
- `bash` - System shell
- `sudo` - Administrative access
- `systemd` - System initialization
- `apt`/`dnf`/`yum`/`pacman`/`zypper` - Package managers
- `dpkg`/`rpm` - Package installers
- `kernel` - System kernel
- `libc` - Core library
- `grub` - Boot loader

### Important Applications (⚠️)
Applications that affect major system functionality:
- `network-manager` - Network management
- `pulseaudio` - Audio system
- `xorg` - Display server
- `gnome-session`/`kde-plasma` - Desktop environments
- `ssh` - Remote access

### Risky Applications (⚠️)
Applications that many other applications depend on:
- `python3`/`perl` - System languages
- `curl`/`wget` - Network tools
- `git` - Version control
- `ca-certificates` - SSL certificates
- `gpg` - Cryptographic tools

### Safe Applications (✓)
Applications that can be removed without affecting system stability.

## User Interaction

### Confirmation Process
1. **Standard Confirmation**: y/n/c (yes/no/cancel)
2. **Risky Application Warning**: Additional warnings for risky applications
3. **Critical Application Protection**: Requires typing "YES I UNDERSTAND THE RISKS"

### Selection Process
- **Toggle Selection**: Use numbers to select/deselect applications
- **Batch Operations**: Select multiple applications at once
- **Visual Feedback**: Selected applications are highlighted
- **Risk Display**: Risk level shown next to each application

## Installation Detection

### Supported Package Managers
- **APT** (Debian/Ubuntu): `apt list --installed`
- **DNF/YUM** (Fedora/RHEL): `dnf list installed`
- **Pacman/Yay** (Arch): `pacman -Q`
- **Zypper** (openSUSE): `zypper search -i`

### Unused Application Detection
- **APT**: Detects packages without dependencies
- **DNF/YUM**: Uses `repoquery --leaves`
- **Pacman**: Uses `pacman -Qtdq` for orphaned packages
- **Fallback**: Basic detection for unsupported managers

## Safety Features

### Pre-removal Checks
- Package installation verification
- Dependency analysis
- Risk assessment
- User confirmation

### Post-removal Cleanup
- Automatic dependency cleanup (`apt autoremove`)
- Package cache cleaning
- Configuration file cleanup
- Log file maintenance

## Logging
All uninstall operations are logged with:
- Timestamp
- Action type (UNINSTALL_SUCCESS/UNINSTALL_FAILED)
- Package name
- User selections
- Risk warnings

## Usage Examples

### Safe Cleanup
```bash
# Select option 7 (Advanced Uninstaller)
# Choose option 2 (Clean Uninstall)
# Select option 1 (Remove safe applications only)
```

### Manual Selection
```bash
# Select option 7 (Advanced Uninstaller)
# Choose option 1 (Manual Selection)
# Toggle applications with numbers
# Type 'go' to proceed
```

### System Analysis
```bash
# Select option 7 (Advanced Uninstaller)
# Choose option 3 (System Scan)
# Review categorized applications
```

## Configuration

### Risk Application Database
The risk database is defined in `modules/uninstaller.sh`:
```bash
declare -A RISKY_APPS=(
    ["bash"]="CRITICAL! System shell - removing this will break your system"
    ["sudo"]="CRITICAL! Administrative access - removing this will break system administration"
    # ... more definitions
)
```

### Customization
- Add new risky applications to `RISKY_APPS` array
- Modify risk levels and descriptions
- Extend detection algorithms
- Add new categories

## Error Handling
- Package manager detection failures
- Permission errors
- Network connectivity issues
- Dependency conflicts
- User cancellation

## Best Practices
1. Always review applications before removal
2. Use "Safe applications only" for routine cleanup
3. Backup important data before major cleanups
4. Test system functionality after removal
5. Keep logs for troubleshooting

## Future Enhancements
- Backup and restore functionality
- Selective configuration cleanup
- Advanced dependency analysis
- Integration with package managers' native tools
- Custom risk profiles
- Automated scheduling
