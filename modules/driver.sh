#!/bin/bash

# KRONUX Driver Installation Module
# Author: Maulana Nais
# Description: Graphics driver installation utilities

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

# Hardware detection state
HAS_INTEL=0
HAS_NVIDIA=0
HAS_AMD=0
IS_INTEL_NEW=0

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
            # Detect if it's a newer Intel GPU (Gen8 and newer support intel-media-driver)
            if echo "$intel_model" | grep -iE "HD Graphics (4|5|6)|UHD Graphics|Iris|Arc" >/dev/null; then
                IS_INTEL_NEW=1
            fi
            continue
        fi
        
        # Detect NVIDIA GPUs (not in VGA devices)
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
    
    # Check for NVIDIA GPUs separately as they might not be in VGA devices
    if ! [[ "$HAS_NVIDIA" == "1" ]] && lspci | grep -i "NVIDIA" | grep -v "nForce" >/dev/null; then
        local nvidia_model=$(lspci | grep -i "NVIDIA" | grep -v "nForce" | cut -d: -f3)
        echo_success "Found NVIDIA GPU: $nvidia_model"
        HAS_NVIDIA=1
    fi
    
    # Check for no GPUs detected
    if [[ -z "$HAS_INTEL" && -z "$HAS_NVIDIA" && -z "$HAS_AMD" ]]; then
        echo_error "No graphics hardware detected!"
        return 1
    fi
    
    return 0
}

# Function to setup package repositories
setup_repositories() {
    local driver_type="$1"
    
    case "$PACKAGE_MANAGER" in
        "apt")
            # Enable non-free repositories for Debian/Ubuntu
            if ! grep -q "non-free" /etc/apt/sources.list; then
                echo_info "Enabling non-free repositories..."
                sudo add-apt-repository non-free
                sudo apt update
            fi
            ;;
        "dnf")
            # Enable RPM Fusion for Fedora
            if [[ ! -f /etc/yum.repos.d/rpmfusion-free.repo ]]; then
                echo_info "Enabling RPM Fusion repositories..."
                sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
                sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
            fi
            ;;
        "pacman"|"yay")
            # Enable multilib for Arch Linux if needed
            if [[ "$driver_type" == "lib32" ]] && ! grep -q "^\[multilib\]" /etc/pacman.conf; then
                echo_info "Enabling multilib repository..."
                sudo sed -i "/\[multilib\]/,/Include/s/^#//" /etc/pacman.conf
                sudo pacman -Sy
            fi
            ;;
        "zypper")
            # Add required repositories for openSUSE
            if ! zypper lr | grep -q "nvidia"; then
                echo_info "Adding required repositories..."
                sudo zypper addrepo -f https://download.nvidia.com/opensuse/tumbleweed NVIDIA
            fi
            ;;
    esac
}

# Function to validate compatible hardware devices
validate_hardware() {
    local driver_type="$1"
    
    # Check dependencies first
    check_dependencies || return 1
    
    # Detect hardware if not already detected
    if [[ -z "$HAS_INTEL" && -z "$HAS_NVIDIA" && -z "$HAS_AMD" ]]; then
        detect_graphics_hardware || return 1
    fi
    
    echo_info "Validating hardware compatibility for $driver_type..."
    
    case "$driver_type" in
        "intel")
            if [[ "$HAS_INTEL" == "1" ]]; then
                echo_success "Intel graphics hardware detected and validated."
                return 0
            else
                echo_error "No compatible Intel graphics hardware detected."
                return 1
            fi
            ;;
        "nvidia")
            if [[ "$HAS_NVIDIA" == "1" ]]; then
                # Check if Nouveau is in use
                if lsmod | grep -q "nouveau"; then
                    echo_warning "Nouveau driver is currently in use. It will need to be disabled before installing NVIDIA drivers."
                fi
                echo_success "NVIDIA hardware detected and validated."
                return 0
            else
                echo_error "No compatible NVIDIA hardware detected."
                return 1
            fi
            ;;
        "amd")
            if [[ "$HAS_AMD" == "1" ]]; then
                echo_success "AMD graphics hardware detected and validated."
                return 0
            else
                echo_error "No compatible AMD graphics hardware detected."
                return 1
            fi
            ;;
        "mesa"|"vulkan"|"lib32")
            # These are generally compatible with any GPU
            echo_success "Hardware validation not required for $driver_type."
            return 0
            ;;
        *)
            echo_warning "Hardware validation not implemented for $driver_type."
            return 0
            ;;
    esac
}

# Function to install graphics drivers based on the type
install_graphics_driver() {
    local driver_type="$1"
    
    # Make sure PKG_MANAGER is defined
    if [[ -z "$PACKAGE_MANAGER" ]]; then
        echo_error "Package manager not defined. Please select a package manager first."
        return 1
    fi
    
    # Validate hardware compatibility
    if ! validate_hardware "$driver_type"; then
        echo_error "Hardware validation failed for $driver_type. Aborting installation."
        return 1
    fi
    
    # Setup necessary repositories
    setup_repositories "$driver_type"
    
    echo_info "Installing $driver_type graphics drivers..."
    
    case "$driver_type" in
        "nvidia")
            case "$PACKAGE_MANAGER" in
                "apt")
                    # Ubuntu/Debian specific preparation
                    if lsmod | grep -q "nouveau"; then
                        echo_info "Creating modprobe blacklist for Nouveau..."
                        echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
                        sudo update-initramfs -u
                    fi
                    # Install NVIDIA drivers
                    install_package "nvidia-driver nvidia-settings"
                    ;;
                "dnf")
                    # Fedora specific preparation
                    if lsmod | grep -q "nouveau"; then
                        echo_info "Creating modprobe blacklist for Nouveau..."
                        echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
                        sudo dracut --force
                    fi
                    install_package "akmod-nvidia xorg-x11-drv-nvidia"
                    ;;
                "pacman"|"yay")
                    install_package "nvidia-dkms nvidia-utils nvidia-settings"
                    ;;
                "zypper")
                    echo_info "For openSUSE, please use YaST or visit: https://en.opensuse.org/SDB:NVIDIA_drivers"
                    echo_info "Manual installation required."
                    ;;
                *)
                    echo_error "Unsupported package manager for NVIDIA drivers: $PACKAGE_MANAGER"
                    return 1
                    ;;
            esac
            ;;
            
        "amd")
            case "$PACKAGE_MANAGER" in
                "apt")
                    install_package "xserver-xorg-video-amdgpu mesa-vulkan-drivers"
                    ;;
                "dnf")
                    # Most AMD drivers are included in the kernel
                    install_package "xorg-x11-drv-amdgpu vulkan-loader"
                    ;;
                "pacman"|"yay")
                    install_package "xf86-video-amdgpu mesa vulkan-radeon"
                    ;;
                "zypper")
                    install_package "xf86-video-amdgpu Mesa-dri"
                    ;;
                *)
                    echo_error "Unsupported package manager for AMD drivers: $PACKAGE_MANAGER"
                    return 1
                    ;;
            esac
            ;;
            
        "intel")
            case "$PACKAGE_MANAGER" in
                "apt")
                    install_package "xserver-xorg-video-intel intel-media-va-driver"
                    ;;
                "dnf")
                    # Most Intel drivers are included in the kernel
                    install_package "xorg-x11-drv-intel intel-media-driver"
                    ;;
                "pacman"|"yay")
                    install_package "xf86-video-intel intel-media-driver"
                    ;;
                "zypper")
                    install_package "xf86-video-intel"
                    ;;
                *)
                    echo_error "Unsupported package manager for Intel drivers: $PACKAGE_MANAGER"
                    return 1
                    ;;
            esac
            ;;
            
        "mesa")
            case "$PACKAGE_MANAGER" in
                "apt")
                    install_package "mesa-utils mesa-vulkan-drivers libegl-mesa0 libgl1-mesa-dri libglapi-mesa libglu1-mesa"
                    ;;
                "dnf")
                    install_package "mesa-dri-drivers mesa-libGL mesa-vulkan-drivers mesa-libEGL mesa-libgbm"
                    ;;
                "pacman"|"yay")
                    install_package "mesa mesa-utils"
                    ;;
                "zypper")
                    install_package "Mesa Mesa-libGL1 Mesa-dri"
                    ;;
                *)
                    echo_error "Unsupported package manager for Mesa drivers: $PACKAGE_MANAGER"
                    return 1
                    ;;
            esac
            ;;
            
        "vulkan")
            case "$PACKAGE_MANAGER" in
                "apt")
                    install_package "vulkan-tools vulkan-validationlayers vulkan-validationlayers-dev mesa-vulkan-drivers"
                    ;;
                "dnf")
                    install_package "vulkan-tools vulkan-validation-layers mesa-vulkan-drivers"
                    ;;
                "pacman"|"yay")
                    install_package "vulkan-icd-loader vulkan-tools vulkan-validation-layers"
                    ;;
                "zypper")
                    install_package "vulkan-tools vulkan-loader"
                    ;;
                *)
                    echo_error "Unsupported package manager for Vulkan drivers: $PACKAGE_MANAGER"
                    return 1
                    ;;
            esac
            ;;
            
        "lib32")
            setup_repositories "lib32"  # Ensure multilib is enabled
            case "$PACKAGE_MANAGER" in
                "apt")
                    if ! dpkg --print-foreign-architectures | grep -q "i386"; then
                        echo_info "Enabling 32-bit architecture support..."
                        sudo dpkg --add-architecture i386
                        sudo apt update
                    fi
                    install_package "libgl1-mesa-dri:i386 libgl1:i386 libc6:i386"
                    ;;
                "dnf")
                    install_package "glibc.i686 libstdc++.i686 mesa-dri-drivers.i686 mesa-libGL.i686"
                    ;;
                "pacman"|"yay")
                    install_package "lib32-mesa lib32-mesa-utils"
                    # Install appropriate 32-bit drivers based on GPU
                    [[ "$HAS_NVIDIA" == "1" ]] && install_package "lib32-nvidia-utils"
                    [[ "$HAS_AMD" == "1" ]] && install_package "lib32-vulkan-radeon"
                    ;;
                "zypper")
                    install_package "Mesa-32bit Mesa-libGL1-32bit"
                    ;;
                *)
                    echo_error "Unsupported package manager for 32-bit graphics libraries: $PACKAGE_MANAGER"
                    return 1
                    ;;
            esac
            ;;
            
        *)
            echo_error "Unknown driver type: $driver_type"
            echo_info "Supported types: nvidia, amd, intel, mesa, vulkan, lib32"
            return 1
            ;;
    esac
    
    # Final steps after installation
    case "$driver_type" in
        "nvidia")
            echo_info "NVIDIA driver installation complete. A system restart is required."
            echo_info "After restart, run 'nvidia-settings' to configure your setup."
            ;;
        "amd"|"intel")
            echo_info "Installation complete. You may need to restart your display manager:"
            echo_info "sudo systemctl restart display-manager"
            ;;
    esac
    
    return 0
}

# Function to install hardware acceleration codecs
install_hw_acceleration() {
    local gpu_type="$1"
    
    # Make sure PKG_MANAGER is defined
    if [[ -z "$PACKAGE_MANAGER" ]]; then
        echo_error "Package manager not defined. Please select a package manager first."
        return 1
    fi
    
    echo_info "Installing hardware acceleration for $gpu_type..."
    
    case "$gpu_type" in
        "intel-new")
            # Hardware acceleration for recent Intel GPUs
            # Reference: https://rpmfusion.org/Howto/Multimedia
            case "$PACKAGE_MANAGER" in
                "apt") install_package "intel-media-driver" ;;
                "dnf") install_package "intel-media-driver" ;;
                "pacman"|"yay") install_package "intel-media-driver" ;;
                "zypper") install_package "intel-media-driver" ;;
                *) echo_error "Unsupported package manager for Intel hardware acceleration: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
            
        "intel-old")
            # Hardware acceleration for older Intel GPUs
            # Reference: https://rpmfusion.org/Howto/Multimedia
            case "$PACKAGE_MANAGER" in
                "apt") install_package "libva-intel-driver" ;;
                "dnf") install_package "libva-intel-driver" ;;
                "pacman"|"yay") install_package "libva-intel-driver" ;;
                "zypper") install_package "libva-intel-driver" ;;
                *) echo_error "Unsupported package manager for Intel hardware acceleration: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
            
        "amd")
            # Hardware acceleration for AMD GPUs
            # Reference: https://rpmfusion.org/Howto/Multimedia
            case "$PACKAGE_MANAGER" in
                "apt") install_package "mesa-va-drivers mesa-vdpau-drivers" ;;
                "dnf") 
                    echo "sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld"
                    echo "sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld"
                    ;;
                "pacman"|"yay") install_package "mesa-vdpau" ;;
                "zypper") install_package "libvdpau1 Mesa-dri" ;;
                *) echo_error "Unsupported package manager for AMD hardware acceleration: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
            
        "amd-32bit")
            # 32-bit hardware acceleration for AMD GPUs (for Steam/Wine)
            # Reference: https://rpmfusion.org/Howto/Multimedia
            case "$PACKAGE_MANAGER" in
                "apt") install_package "mesa-va-drivers:i386 mesa-vdpau-drivers:i386" ;;
                "dnf") 
                    echo "sudo dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686"
                    echo "sudo dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686"
                    ;;
                "pacman"|"yay") install_package "lib32-mesa-vdpau" ;;
                "zypper") install_package "libvdpau1-32bit Mesa-dri-32bit" ;;
                *) echo_error "Unsupported package manager for 32-bit AMD hardware acceleration: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
            
        "nvidia-vaapi")
            # NVIDIA VAAPI bridge (for hardware acceleration with NVIDIA)
            # Reference: https://rpmfusion.org/Howto/Multimedia
            case "$PACKAGE_MANAGER" in
                "apt") install_package "libva-nvidia-driver" ;;
                "dnf") install_package "libva-nvidia-driver" ;;
                "pacman"|"yay") install_package "libva-nvidia-driver" ;;
                "zypper") install_package "libva-nvidia-driver" ;;
                *) echo_error "Unsupported package manager for NVIDIA VAAPI bridge: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
            
        "nvidia-vaapi-32bit")
            # 32-bit NVIDIA VAAPI bridge (for hardware acceleration with NVIDIA for 32-bit apps)
            # Reference: https://rpmfusion.org/Howto/Multimedia
            case "$PACKAGE_MANAGER" in
                "apt") install_package "libva-nvidia-driver:i386" ;;
                "dnf") install_package "libva-nvidia-driver.i686" ;;
                "pacman"|"yay") install_package "lib32-libva-nvidia-driver" ;;
                "zypper") install_package "libva-nvidia-driver-32bit" ;;
                *) echo_error "Unsupported package manager for 32-bit NVIDIA VAAPI bridge: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
            
        "dvd")
            # DVD playback support
            # Reference: https://rpmfusion.org/Howto/Multimedia
            case "$PACKAGE_MANAGER" in
                "apt") install_package "libdvdcss2" ;;
                "dnf") 
                    echo "sudo dnf install -y rpmfusion-free-release-tainted"
                    echo "sudo dnf install -y libdvdcss"
                    ;;
                "pacman"|"yay") install_package "libdvdcss" ;;
                "zypper") install_package "libdvdcss2" ;;
                *) echo_error "Unsupported package manager for DVD playback support: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
            
        "firmware")
            # Various firmware packages
            # Reference: https://rpmfusion.org/Howto/Multimedia
            case "$PACKAGE_MANAGER" in
                "apt") install_package "firmware-linux firmware-linux-nonfree" ;;
                "dnf") 
                    echo "sudo dnf install -y rpmfusion-nonfree-release-tainted"
                    echo "sudo dnf --repo=rpmfusion-nonfree-tainted install -y \"*-firmware\""
                    ;;
                "pacman"|"yay") install_package "linux-firmware" ;;
                "zypper") install_package "kernel-firmware-*" ;;
                *) echo_error "Unsupported package manager for firmware packages: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
            
        *)
            echo_error "Unknown hardware acceleration type: $gpu_type"
            echo_info "Supported types: intel-new, intel-old, amd, amd-32bit, nvidia-vaapi, nvidia-vaapi-32bit, dvd, firmware"
            return 1
            ;;
    esac
    
    return 0
}
