#!/bin/bash

# KRONUX Uninstaller Module
# Author: Maulana Nais
# Description: Advanced uninstaller with automatic detection and risk assessment

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

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
    while true; do
        clear
        show_ascii_logo
        show_header "ADVANCED UNINSTALLER"
        
        echo_info "Choose uninstall mode:"
        echo_menu_item "1" "Manual Selection - Choose specific applications to uninstall"
        echo_menu_item "2" "Clean Uninstall - Automatically detect and remove unused applications"
        echo_menu_item "3" "Scan System - Show all installed applications with risk assessment"
        echo_menu_item "4" "Uninstall by Category - Remove applications by type"
        echo_menu_item "0" "Back to Main Menu"
        
        show_footer
        
        read -p "Enter your choice [0-4]: " choice
        
        case $choice in
            1) show_manual_uninstall_menu ;;
            2) show_clean_uninstall_menu ;;
            3) show_system_scan ;;
            4) show_category_uninstall_menu ;;
            0) pop_nav; ${NAV_STACK[-1]}; return ;;
            *) echo_error "Invalid choice. Please try again."; sleep 1 ;;
        esac
    done
}

# Manual selection uninstall menu with pagination
show_manual_uninstall_menu() {
    clear
    show_ascii_logo
    show_header "MANUAL UNINSTALL SELECTION"
    
    echo_info "Detecting installed applications..."
    local installed_apps=($(get_installed_applications))
    
    if [[ ${#installed_apps[@]} -eq 0 ]]; then
        echo_warning "No applications detected for manual uninstall"
        pause_for_user
        return
    fi
    
    echo_info "Found ${#installed_apps[@]} applications"
    echo_info "Applications will be shown in pages of 20 for better navigation"
    echo
    
    SELECTED_ITEMS=()
    local current_page=1
    local items_per_page=20
    local total_pages=$(( (${#installed_apps[@]} + items_per_page - 1) / items_per_page ))
    
    while true; do
        clear
        show_ascii_logo
        show_header "MANUAL UNINSTALL SELECTION"
        
        echo_info "Page $current_page of $total_pages (${#installed_apps[@]} total applications)"
        echo_info "Navigation: 'n' next page, 'p' previous page, 'go' to proceed"
        echo
        
        # Calculate range for current page
        local start_idx=$(( (current_page - 1) * items_per_page ))
        local end_idx=$(( start_idx + items_per_page - 1 ))
        if [[ $end_idx -ge ${#installed_apps[@]} ]]; then
            end_idx=$((${#installed_apps[@]} - 1))
        fi
        
        # Display applications for current page
        for i in $(seq $start_idx $end_idx); do
            local app="${installed_apps[i]}"
            local display_number=$((i + 1))
            local status=""
            local risk_warning=""
            
            # Check if selected
            for sel in "${SELECTED_ITEMS[@]}"; do
                [[ "$sel" == "$app" ]] && status="${GREEN}[SELECTED]${NC}" && break
            done
            
            # Check if risky
            if [[ -n "${RISKY_APPS[$app]}" ]]; then
                risk_warning="${RED}[${RISKY_APPS[$app]%!*}!]${NC}"
            fi
            
            echo_menu_item "$display_number" "$app $risk_warning" "$status"
        done
        
        echo
        echo_menu_item "go" "Proceed with uninstall"
        echo_menu_item "n" "Next page"
        echo_menu_item "p" "Previous page"
        echo_menu_item "search" "Search applications"
        echo_menu_item "0" "Back"
        
        show_footer
        
        if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
            echo_info "Selected for uninstall (${#SELECTED_ITEMS[@]}):"
            local shown_count=0
            for item in "${SELECTED_ITEMS[@]}"; do
                if [[ $shown_count -lt 5 ]]; then
                    if [[ -n "${RISKY_APPS[$item]}" ]]; then
                        echo -e "  ${RED}⚠${NC} $item - ${RISKY_APPS[$item]}"
                    else
                        echo -e "  ${GREEN}•${NC} $item"
                    fi
                    ((shown_count++))
                fi
            done
            if [[ ${#SELECTED_ITEMS[@]} -gt 5 ]]; then
                echo_info "... and $((${#SELECTED_ITEMS[@]} - 5)) more selected"
            fi
        else
            echo_info "No applications selected for uninstall"
        fi
        
        read -p "Enter your selection: " selection
        
        case "${selection,,}" in
            "go")
                if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
                    confirm_and_uninstall_selected
                    return
                else
                    echo_error "No applications selected!"; sleep 1
                fi
                ;;
            "n"|"next")
                if [[ $current_page -lt $total_pages ]]; then
                    ((current_page++))
                else
                    echo_info "Already at last page"
                    sleep 1
                fi
                ;;
            "p"|"prev"|"previous")
                if [[ $current_page -gt 1 ]]; then
                    ((current_page--))
                else
                    echo_info "Already at first page"
                    sleep 1
                fi
                ;;
            "search")
                search_and_select_applications installed_apps
                ;;
            "0"|"back")
                SELECTED_ITEMS=()
                return
                ;;
            *)
                if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 && $selection -le ${#installed_apps[@]} ]]; then
                    local app="${installed_apps[$((selection-1))]}"
                    toggle_selection "$app"
                else
                    echo_error "Invalid selection: $selection"; sleep 1
                fi
                ;;
        esac
    done
}

# Search and select applications
search_and_select_applications() {
    local -n apps_array=$1
    
    echo_info "Enter search term (package name or partial name):"
    read -p "Search: " search_term
    
    if [[ -z "$search_term" ]]; then
        echo_error "No search term provided"
        sleep 1
        return
    fi
    
    # Find matching applications
    local matching_apps=()
    for app in "${apps_array[@]}"; do
        if [[ "$app" =~ $search_term ]]; then
            matching_apps+=("$app")
        fi
    done
    
    if [[ ${#matching_apps[@]} -eq 0 ]]; then
        echo_warning "No applications found matching '$search_term'"
        sleep 2
        return
    fi
    
    clear
    show_ascii_logo
    show_header "SEARCH RESULTS"
    
    echo_info "Found ${#matching_apps[@]} applications matching '$search_term':"
    echo
    
    for i in "${!matching_apps[@]}"; do
        local app="${matching_apps[i]}"
        local number=$((i + 1))
        local status=""
        local risk_warning=""
        
        # Check if selected
        for sel in "${SELECTED_ITEMS[@]}"; do
            [[ "$sel" == "$app" ]] && status="${GREEN}[SELECTED]${NC}" && break
        done
        
        # Check if risky
        if [[ -n "${RISKY_APPS[$app]}" ]]; then
            risk_warning="${RED}[${RISKY_APPS[$app]%!*}!]${NC}"
        fi
        
        echo_menu_item "$number" "$app $risk_warning" "$status"
    done
    
    echo_menu_item "all" "Select all search results"
    echo_menu_item "clear" "Clear all selections"
    echo_menu_item "0" "Back to main selection"
    
    show_footer
    
    read -p "Enter your selection (numbers, 'all', 'clear', or '0'): " selection
    
    case "${selection,,}" in
        "all")
            for app in "${matching_apps[@]}"; do
                # Add to selection if not already selected
                local found=false
                for sel in "${SELECTED_ITEMS[@]}"; do
                    [[ "$sel" == "$app" ]] && found=true && break
                done
                if [[ "$found" == false ]]; then
                    SELECTED_ITEMS+=("$app")
                fi
            done
            echo_success "Selected all ${#matching_apps[@]} matching applications"
            sleep 1
            ;;
        "clear")
            SELECTED_ITEMS=()
            echo_info "Cleared all selections"
            sleep 1
            ;;
        "0"|"back")
            return
            ;;
        *)
            # Handle multiple selections
            IFS=' ' read -ra SELECTIONS <<< "$selection"
            for sel in "${SELECTIONS[@]}"; do
                if [[ "$sel" =~ ^[0-9]+$ ]] && [[ $sel -ge 1 && $sel -le ${#matching_apps[@]} ]]; then
                    local app="${matching_apps[$((sel-1))]}"
                    toggle_selection "$app"
                else
                    echo_error "Invalid selection: $sel"
                fi
            done
            sleep 1
            ;;
    esac
}

# Clean uninstall menu
show_clean_uninstall_menu() {
    clear
    show_ascii_logo
    show_header "CLEAN UNINSTALL - AUTOMATIC DETECTION"
    
    echo_info "Scanning system for unused and safe-to-remove applications..."
    echo_progress "This may take a moment..."
    
    local unused_apps=($(detect_unused_applications))
    local safe_apps=($(filter_safe_applications "${unused_apps[@]}"))
    local risky_apps=($(filter_risky_applications "${unused_apps[@]}"))
    
    echo
    echo_info "Scan Results:"
    echo_info "• Safe to remove: ${#safe_apps[@]} applications"
    echo_info "• Risky to remove: ${#risky_apps[@]} applications"
    echo_info "• Total detected: ${#unused_apps[@]} applications"
    echo
    
    if [[ ${#safe_apps[@]} -eq 0 && ${#risky_apps[@]} -eq 0 ]]; then
        echo_success "No unused applications detected! Your system is clean."
        pause_for_user
        return
    fi
    
    # Show safe applications
    if [[ ${#safe_apps[@]} -gt 0 ]]; then
        echo_info "Safe applications that can be removed:"
        for app in "${safe_apps[@]}"; do
            echo -e "  ${GREEN}✓${NC} $app"
        done
        echo
    fi
    
    # Show risky applications
    if [[ ${#risky_apps[@]} -gt 0 ]]; then
        echo_warning "Risky applications that require caution:"
        for app in "${risky_apps[@]}"; do
            echo -e "  ${RED}⚠${NC} $app - ${RISKY_APPS[$app]}"
        done
        echo
    fi
    
    echo_info "Clean uninstall options:"
    echo_menu_item "1" "Remove safe applications only (recommended)"
    echo_menu_item "2" "Remove safe + risky applications (advanced users)"
    echo_menu_item "3" "Custom selection from detected applications"
    echo_menu_item "0" "Cancel and return"
    
    read -p "Enter your choice [0-3]: " choice
    
    case $choice in
        1)
            if [[ ${#safe_apps[@]} -gt 0 ]]; then
                SELECTED_ITEMS=("${safe_apps[@]}")
                confirm_and_uninstall_selected
            else
                echo_info "No safe applications to remove"
                sleep 2
            fi
            ;;
        2)
            if [[ ${#unused_apps[@]} -gt 0 ]]; then
                SELECTED_ITEMS=("${unused_apps[@]}")
                confirm_and_uninstall_selected
            else
                echo_info "No applications to remove"
                sleep 2
            fi
            ;;
        3)
            if [[ ${#unused_apps[@]} -gt 0 ]]; then
                show_custom_selection_from_detected "${unused_apps[@]}"
            else
                echo_info "No applications detected for custom selection"
                sleep 2
            fi
            ;;
        0)
            return
            ;;
        *)
            echo_error "Invalid choice"
            sleep 1
            show_clean_uninstall_menu
            ;;
    esac
}

# Custom selection from detected applications
show_custom_selection_from_detected() {
    local detected_apps=("$@")
    SELECTED_ITEMS=()
    
    while true; do
        clear
        show_ascii_logo
        show_header "CUSTOM SELECTION - DETECTED APPLICATIONS"
        
        echo_info "Select applications to uninstall (toggle with numbers, 'go' to proceed):"
        echo
        
        for i in "${!detected_apps[@]}"; do
            local app="${detected_apps[i]}"
            local number=$((i + 1))
            local status=""
            local risk_warning=""
            
            # Check if selected
            for sel in "${SELECTED_ITEMS[@]}"; do
                [[ "$sel" == "$app" ]] && status="${GREEN}[SELECTED]${NC}" && break
            done
            
            # Check if risky
            if [[ -n "${RISKY_APPS[$app]}" ]]; then
                risk_warning="${RED}[${RISKY_APPS[$app]%!*}!]${NC}"
            fi
            
            echo_menu_item "$number" "$app $risk_warning" "$status"
        done
        
        echo_menu_item "go" "Proceed with uninstall"
        echo_menu_item "0" "Back"
        
        show_footer
        
        if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
            echo_info "Selected for uninstall (${#SELECTED_ITEMS[@]}):"
            for item in "${SELECTED_ITEMS[@]}"; do
                if [[ -n "${RISKY_APPS[$item]}" ]]; then
                    echo -e "  ${RED}⚠${NC} $item - ${RISKY_APPS[$item]}"
                else
                    echo -e "  ${GREEN}•${NC} $item"
                fi
            done
        else
            echo_info "No applications selected for uninstall"
        fi
        
        read -p "Enter your selection: " selection
        
        case "${selection,,}" in
            "go")
                if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
                    confirm_and_uninstall_selected
                    return
                else
                    echo_error "No applications selected!"; sleep 1
                fi
                ;;
            "0"|"back")
                SELECTED_ITEMS=()
                return
                ;;
            *)
                if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 && $selection -le ${#detected_apps[@]} ]]; then
                    local app="${detected_apps[$((selection-1))]}"
                    toggle_selection "$app"
                else
                    echo_error "Invalid selection: $selection"; sleep 1
                fi
                ;;
        esac
    done
}

# System scan to show all installed applications
show_system_scan() {
    clear
    show_ascii_logo
    show_header "SYSTEM SCAN - ALL INSTALLED APPLICATIONS"
    
    echo_info "Scanning system for all installed applications..."
    echo_progress "This may take a moment..."
    
    local all_apps=($(get_all_installed_packages))
    
    if [[ ${#all_apps[@]} -eq 0 ]]; then
        echo_error "Failed to detect installed applications"
        pause_for_user
        return
    fi
    
    echo_info "Found ${#all_apps[@]} installed packages"
    echo
    
    # Categorize applications
    local critical_apps=()
    local important_apps=()
    local risky_apps=()
    local safe_apps=()
    
    for app in "${all_apps[@]}"; do
        if [[ -n "${RISKY_APPS[$app]}" ]]; then
            case "${RISKY_APPS[$app]}" in
                CRITICAL*) critical_apps+=("$app") ;;
                IMPORTANT*) important_apps+=("$app") ;;
                RISK*) risky_apps+=("$app") ;;
            esac
        else
            safe_apps+=("$app")
        fi
    done
    
    # Display results
    if [[ ${#critical_apps[@]} -gt 0 ]]; then
        echo_error "CRITICAL APPLICATIONS (${#critical_apps[@]}) - DO NOT REMOVE:"
        for app in "${critical_apps[@]}"; do
            echo -e "  ${RED}🚫${NC} $app - ${RISKY_APPS[$app]}"
        done
        echo
    fi
    
    if [[ ${#important_apps[@]} -gt 0 ]]; then
        echo_warning "IMPORTANT APPLICATIONS (${#important_apps[@]}) - REMOVE WITH CAUTION:"
        for app in "${important_apps[@]}"; do
            echo -e "  ${YELLOW}⚠${NC} $app - ${RISKY_APPS[$app]}"
        done
        echo
    fi
    
    if [[ ${#risky_apps[@]} -gt 0 ]]; then
        echo_info "RISKY APPLICATIONS (${#risky_apps[@]}) - CONSIDER CAREFULLY:"
        for app in "${risky_apps[@]}"; do
            echo -e "  ${PURPLE}⚠${NC} $app - ${RISKY_APPS[$app]}"
        done
        echo
    fi
    
    echo_success "SAFE APPLICATIONS (${#safe_apps[@]}) - CAN BE REMOVED SAFELY:"
    local count=0
    for app in "${safe_apps[@]}"; do
        if [[ $count -lt 20 ]]; then  # Show first 20 safe apps
            echo -e "  ${GREEN}✓${NC} $app"
            ((count++))
        fi
    done
    
    if [[ ${#safe_apps[@]} -gt 20 ]]; then
        echo_info "... and $((${#safe_apps[@]} - 20)) more safe applications"
    fi
    
    echo
    echo_info "Scan complete! Use other uninstall options to remove applications."
    pause_for_user
}

# Category-based uninstall menu
show_category_uninstall_menu() {
    clear
    show_ascii_logo
    show_header "UNINSTALL BY CATEGORY"
    
    echo_info "Choose application category to uninstall:"
    echo_menu_item "1" "Development Tools"
    echo_menu_item "2" "Web Browsers"
    echo_menu_item "3" "Multimedia Applications"
    echo_menu_item "4" "Games"
    echo_menu_item "5" "Office Applications"
    echo_menu_item "6" "System Utilities"
    echo_menu_item "7" "Language Packages"
    echo_menu_item "8" "Orphaned Packages"
    echo_menu_item "0" "Back"
    
    show_footer
    
    read -p "Enter your choice [0-8]: " choice
    
    case $choice in
        1) uninstall_category "development" ;;
        2) uninstall_category "browsers" ;;
        3) uninstall_category "multimedia" ;;
        4) uninstall_category "games" ;;
        5) uninstall_category "office" ;;
        6) uninstall_category "system" ;;
        7) uninstall_category "languages" ;;
        8) uninstall_orphaned_packages ;;
        0) return ;;
        *) echo_error "Invalid choice"; sleep 1; show_category_uninstall_menu ;;
    esac
}

# Confirm and uninstall selected applications
confirm_and_uninstall_selected() {
    local risky_count=0
    local critical_count=0
    
    # Count risky applications
    for app in "${SELECTED_ITEMS[@]}"; do
        if [[ -n "${RISKY_APPS[$app]}" ]]; then
            case "${RISKY_APPS[$app]}" in
                CRITICAL*) ((critical_count++)) ;;
                *) ((risky_count++)) ;;
            esac
        fi
    done
    
    clear
    show_ascii_logo
    show_header "CONFIRM UNINSTALL"
    
    echo_info "You are about to uninstall ${#SELECTED_ITEMS[@]} applications:"
    echo
    
    for app in "${SELECTED_ITEMS[@]}"; do
        if [[ -n "${RISKY_APPS[$app]}" ]]; then
            case "${RISKY_APPS[$app]}" in
                CRITICAL*) echo -e "  ${RED}🚫${NC} $app - ${RISKY_APPS[$app]}" ;;
                IMPORTANT*) echo -e "  ${YELLOW}⚠${NC} $app - ${RISKY_APPS[$app]}" ;;
                *) echo -e "  ${PURPLE}⚠${NC} $app - ${RISKY_APPS[$app]}" ;;
            esac
        else
            echo -e "  ${GREEN}•${NC} $app"
        fi
    done
    
    echo
    
    if [[ $critical_count -gt 0 ]]; then
        echo_error "WARNING: $critical_count CRITICAL applications selected!"
        echo_error "Removing these may make your system unusable!"
        echo
    fi
    
    if [[ $risky_count -gt 0 ]]; then
        echo_warning "WARNING: $risky_count risky applications selected!"
        echo_warning "These may affect system functionality!"
        echo
    fi
    
    echo_info "Package Manager: $PACKAGE_MANAGER"
    echo_info "Total applications to remove: ${#SELECTED_ITEMS[@]}"
    echo
    
    if [[ $critical_count -gt 0 ]]; then
        echo_error "CRITICAL applications detected! Are you absolutely sure?"
        echo_info "Type 'YES I UNDERSTAND THE RISKS' to proceed with critical removals:"
        read -r critical_response
        if [[ "$critical_response" != "YES I UNDERSTAND THE RISKS" ]]; then
            echo_info "Uninstall cancelled for safety."
            pause_for_user
            return
        fi
    fi
    
    echo_warning "Are you sure you want to uninstall these applications?"
    echo_info "This action cannot be undone!"
    echo
    echo_info "Enter your choice:"
    echo_info "  y - Yes, proceed with uninstall"
    echo_info "  n - No, cancel uninstall"
    echo_info "  c - Cancel and return to menu"
    echo
    
    read -p "Your choice [y/n/c]: " response
    
    case "${response,,}" in
        "y"|"yes")
            execute_uninstall
            ;;
        "n"|"no")
            echo_info "Uninstall cancelled."
            sleep 1
            ;;
        "c"|"cancel")
            echo_info "Returning to menu..."
            sleep 1
            ;;
        *)
            echo_error "Invalid choice. Uninstall cancelled."
            sleep 1
            ;;
    esac
    
    SELECTED_ITEMS=()
    pause_for_user
}

# Execute the uninstall process
execute_uninstall() {
    local success_count=0
    local failure_count=0
    local skipped_count=0
    
    echo_progress "Starting uninstall process..."
    echo
    
    for app in "${SELECTED_ITEMS[@]}"; do
        echo_progress "Uninstalling $app..."
        
        if uninstall_application "$app"; then
            echo_success "Successfully uninstalled $app"
            ((success_count++))
        else
            echo_error "Failed to uninstall $app"
            ((failure_count++))
        fi
    done
    
    echo
    echo_info "=== UNINSTALL SUMMARY ==="
    echo_success "Successfully uninstalled: $success_count applications"
    if [[ $failure_count -gt 0 ]]; then
        echo_error "Failed to uninstall: $failure_count applications"
    fi
    if [[ $skipped_count -gt 0 ]]; then
        echo_info "Skipped: $skipped_count applications"
    fi
    echo_info "Check logs at: $LOG_FILE"
    echo
    
    # Clean up after uninstall
    if [[ $success_count -gt 0 ]]; then
        echo_progress "Cleaning up after uninstall..."
        cleanup_after_uninstall
        echo_success "Cleanup completed!"
    fi
}

# Helper functions for application detection and management
get_installed_applications() {
    case "$PACKAGE_MANAGER" in
        "apt")
            apt list --installed 2>/dev/null | grep -E '^[^/]+' | cut -d'/' -f1 | grep -v "^WARNING" | sort | uniq
            ;;
        "dnf"|"yum")
            $PACKAGE_MANAGER list installed 2>/dev/null | grep -E '^[^[:space:]]+' | awk '{print $1}' | cut -d'.' -f1 | sort | uniq
            ;;
        "pacman"|"yay")
            pacman -Q 2>/dev/null | awk '{print $1}' | sort | uniq
            ;;
        "zypper")
            zypper search -i 2>/dev/null | grep '^i' | awk '{print $3}' | sort | uniq
            ;;
        *)
            echo_error "Package manager not supported for application detection"
            return 1
            ;;
    esac
}

get_all_installed_packages() {
    get_installed_applications
}

detect_unused_applications() {
    # This is a simplified implementation
    # In a real scenario, you'd want more sophisticated detection
    case "$PACKAGE_MANAGER" in
        "apt")
            # Find packages that are not dependencies of other packages
            comm -23 <(apt list --installed 2>/dev/null | grep -E '^[^/]+' | cut -d'/' -f1 | grep -v "^WARNING" | sort) \
                     <(apt-cache depends $(apt list --installed 2>/dev/null | grep -E '^[^/]+' | cut -d'/' -f1 | grep -v "^WARNING") 2>/dev/null | grep "Depends:" | awk '{print $2}' | sort | uniq) 2>/dev/null || true
            ;;
        "dnf"|"yum")
            # Find leaf packages (packages with no dependencies)
            $PACKAGE_MANAGER repoquery --installed --leaves 2>/dev/null | cut -d'.' -f1 | sort | uniq || true
            ;;
        "pacman"|"yay")
            # Find orphaned packages
            pacman -Qtdq 2>/dev/null || true
            ;;
        *)
            # Fallback to basic detection
            get_installed_applications | head -20
            ;;
    esac
}

filter_safe_applications() {
    local apps=("$@")
    local safe_apps=()
    
    for app in "${apps[@]}"; do
        if [[ -z "${RISKY_APPS[$app]}" ]]; then
            safe_apps+=("$app")
        fi
    done
    
    printf '%s\n' "${safe_apps[@]}"
}

filter_risky_applications() {
    local apps=("$@")
    local risky_apps=()
    
    for app in "${apps[@]}"; do
        if [[ -n "${RISKY_APPS[$app]}" ]]; then
            risky_apps+=("$app")
        fi
    done
    
    printf '%s\n' "${risky_apps[@]}"
}

uninstall_application() {
    local app="$1"
    
    case "$PACKAGE_MANAGER" in
        "apt")
            if sudo apt remove -y "$app" && sudo apt autoremove -y; then
                log_action "UNINSTALL_SUCCESS" "$app"
                return 0
            else
                log_action "UNINSTALL_FAILED" "$app"
                return 1
            fi
            ;;
        "dnf")
            if sudo dnf remove -y "$app"; then
                log_action "UNINSTALL_SUCCESS" "$app"
                return 0
            else
                log_action "UNINSTALL_FAILED" "$app"
                return 1
            fi
            ;;
        "yum")
            if sudo yum remove -y "$app"; then
                log_action "UNINSTALL_SUCCESS" "$app"
                return 0
            else
                log_action "UNINSTALL_FAILED" "$app"
                return 1
            fi
            ;;
        "pacman"|"yay")
            if yay -R --noconfirm "$app"; then
                log_action "UNINSTALL_SUCCESS" "$app"
                return 0
            else
                log_action "UNINSTALL_FAILED" "$app"
                return 1
            fi
            ;;
        "zypper")
            if sudo zypper remove -y "$app"; then
                log_action "UNINSTALL_SUCCESS" "$app"
                return 0
            else
                log_action "UNINSTALL_FAILED" "$app"
                return 1
            fi
            ;;
        *)
            echo_error "Package manager not supported for uninstall"
            return 1
            ;;
    esac
}

# Get applications by category
get_category_applications() {
    local category="$1"
    local all_apps=($(get_installed_applications))
    local category_apps=()
    
    case "$category" in
        "development")
            # Development tools patterns
            local dev_patterns=(
                "git" "gcc" "g++" "make" "cmake" "build-essential" "nodejs" "npm" "yarn"
                "python3-dev" "python3-pip" "pip" "pip3" "ruby" "ruby-dev" "golang"
                "java" "openjdk" "maven" "gradle" "ant" "composer" "php-dev"
                "vim" "emacs" "nano" "code" "vscode" "atom" "sublime" "gedit"
                "docker" "docker-compose" "kubernetes" "kubectl" "terraform"
                "ansible" "vagrant" "virtualbox" "gdb" "valgrind" "strace"
                "curl" "wget" "postman" "insomnia" "jq" "httpie"
            )
            ;;
        "browsers")
            # Web browsers patterns
            local dev_patterns=(
                "firefox" "chrome" "chromium" "brave" "opera" "vivaldi" "edge"
                "microsoft-edge" "google-chrome" "firefox-esr" "brave-browser"
                "links" "lynx" "elinks" "w3m" "tor-browser" "torbrowser"
            )
            ;;
        "multimedia")
            # Multimedia applications patterns
            local dev_patterns=(
                "vlc" "mpv" "mplayer" "totem" "rhythmbox" "banshee" "clementine"
                "spotify" "audacity" "gimp" "inkscape" "blender" "krita"
                "ffmpeg" "handbrake" "obs" "kdenlive" "openshot" "shotcut"
                "cheese" "guvcview" "simplescreenrecorder" "peek" "flameshot"
                "imagemagick" "gthumb" "shotwell" "digikam" "rawtherapee"
                "audacious" "amarok" "strawberry" "lollypop" "parole"
            )
            ;;
        "games")
            # Games patterns
            local dev_patterns=(
                "steam" "lutris" "wine" "playonlinux" "gamemode" "mangohud"
                "retroarch" "dolphin-emu" "pcsx2" "ppsspp" "mupen64plus"
                "gnome-games" "kde-games" "aisleriot" "mahjongg" "mines"
                "quadrapassel" "solitaire" "sudoku" "tali" "chess"
                "0ad" "supertux" "frozen-bubble" "pingus" "wesnoth"
                "openttd" "freeciv" "scorched3d" "warzone2100" "xonotic"
            )
            ;;
        "office")
            # Office applications patterns
            local dev_patterns=(
                "libreoffice" "openoffice" "onlyoffice" "calligra" "abiword"
                "gnumeric" "scribus" "okular" "evince" "zathura" "mupdf"
                "thunderbird" "evolution" "kmail" "mutt" "alpine"
                "keepass" "bitwarden" "password-gorilla" "revelation"
                "zim" "cherrytree" "tomboy" "gnote" "xournal" "rnote"
                "calibre" "fbreader" "foliate" "bookworm" "sigil"
            )
            ;;
        "system")
            # System utilities patterns  
            local dev_patterns=(
                "htop" "btop" "top" "iotop" "nethogs" "iftop" "nmon"
                "gparted" "fdisk" "parted" "cfdisk" "gdisk" "partitionmanager"
                "timeshift" "rsync" "borgbackup" "duplicity" "deja-dup"
                "bleachbit" "stacer" "sweeper" "fslint" "rmlint"
                "synaptic" "muon" "packagekit" "gnome-software" "discover"
                "gufw" "ufw" "iptables" "firewall-config" "opensnitch"
                "wireshark" "tcpdump" "nmap" "netstat" "ss" "lsof"
                "gnome-system-monitor" "ksysguard" "system-monitor" "task-manager"
            )
            ;;
        "languages")
            # Language packages patterns
            local dev_patterns=(
                "language-pack" "locale" "l10n" "i18n" "aspell" "hunspell"
                "mythes" "hyphen" "wamerican" "wbritish" "wfrench" "wgerman"
                "fonts-" "ttf-" "otf-" "texlive" "latex" "pandoc"
                "ibus" "fcitx" "scim" "uim" "mozc" "anthy" "pinyin"
                "translate" "goldendict" "stardict" "dict" "festival"
                "espeak" "speech-dispatcher" "orca" "brltty" "dasher"
            )
            ;;
        *)
            echo_error "Unknown category: $category"
            return 1
            ;;
    esac
    
    # Find matching applications
    for app in "${all_apps[@]}"; do
        for pattern in "${dev_patterns[@]}"; do
            if [[ "$app" =~ $pattern ]]; then
                category_apps+=("$app")
                break
            fi
        done
    done
    
    # Remove duplicates and sort
    printf '%s\n' "${category_apps[@]}" | sort -u
}

uninstall_category() {
    local category="$1"
    clear
    show_ascii_logo
    show_header "UNINSTALL BY CATEGORY - ${category^^}"
    
    echo_info "Detecting $category applications..."
    local category_apps=($(get_category_applications "$category"))
    
    if [[ ${#category_apps[@]} -eq 0 ]]; then
        echo_warning "No $category applications found on your system"
        pause_for_user
        return
    fi
    
    echo_info "Found ${#category_apps[@]} $category applications:"
    echo
    
    SELECTED_ITEMS=()
    
    while true; do
        clear
        show_ascii_logo
        show_header "UNINSTALL BY CATEGORY - ${category^^}"
        
        echo_info "Select $category applications to uninstall (toggle with numbers, 'go' to proceed):"
        echo
        
        for i in "${!category_apps[@]}"; do
            local app="${category_apps[i]}"
            local number=$((i + 1))
            local status=""
            local risk_warning=""
            
            # Check if selected
            for sel in "${SELECTED_ITEMS[@]}"; do
                [[ "$sel" == "$app" ]] && status="${GREEN}[SELECTED]${NC}" && break
            done
            
            # Check if risky
            if [[ -n "${RISKY_APPS[$app]}" ]]; then
                risk_warning="${RED}[${RISKY_APPS[$app]%!*}!]${NC}"
            fi
            
            echo_menu_item "$number" "$app $risk_warning" "$status"
        done
        
        echo
        echo_menu_item "all" "Select all $category applications"
        echo_menu_item "go" "Proceed with uninstall"
        echo_menu_item "0" "Back"
        
        show_footer
        
        if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
            echo_info "Selected for uninstall (${#SELECTED_ITEMS[@]}):"
            for item in "${SELECTED_ITEMS[@]}"; do
                if [[ -n "${RISKY_APPS[$item]}" ]]; then
                    echo -e "  ${RED}⚠${NC} $item - ${RISKY_APPS[$item]}"
                else
                    echo -e "  ${GREEN}•${NC} $item"
                fi
            done
        else
            echo_info "No $category applications selected for uninstall"
        fi
        
        read -p "Enter your selection: " selection
        
        case "${selection,,}" in
            "go")
                if [[ ${#SELECTED_ITEMS[@]} -gt 0 ]]; then
                    confirm_and_uninstall_selected
                    return
                else
                    echo_error "No applications selected!"; sleep 1
                fi
                ;;
            "all")
                SELECTED_ITEMS=("${category_apps[@]}")
                echo_success "Selected all ${#category_apps[@]} $category applications"
                sleep 1
                ;;
            "0"|"back")
                SELECTED_ITEMS=()
                return
                ;;
            *)
                if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 && $selection -le ${#category_apps[@]} ]]; then
                    local app="${category_apps[$((selection-1))]}"
                    toggle_selection "$app"
                else
                    echo_error "Invalid selection: $selection"; sleep 1
                fi
                ;;
        esac
    done
}

uninstall_orphaned_packages() {
    clear
    show_ascii_logo
    show_header "UNINSTALL ORPHANED PACKAGES"
    
    echo_info "Detecting orphaned packages..."
    
    case "$PACKAGE_MANAGER" in
        "apt")
            local orphaned=($(deborphan 2>/dev/null || apt autoremove --dry-run 2>/dev/null | grep "^Remv" | awk '{print $2}' || true))
            ;;
        "dnf"|"yum")
            local orphaned=($(package-cleanup --leaves --all 2>/dev/null | grep -v "^No" || true))
            ;;
        "pacman"|"yay")
            local orphaned=($(pacman -Qtdq 2>/dev/null || true))
            ;;
        *)
            echo_error "Orphaned package detection not supported for $PACKAGE_MANAGER"
            pause_for_user
            return
            ;;
    esac
    
    if [[ ${#orphaned[@]} -eq 0 ]]; then
        echo_success "No orphaned packages found!"
        pause_for_user
        return
    fi
    
    echo_info "Found ${#orphaned[@]} orphaned packages:"
    for pkg in "${orphaned[@]}"; do
        echo -e "  ${GREEN}•${NC} $pkg"
    done
    
    echo
    echo_warning "Remove all orphaned packages? [y/N]"
    read -r response
    
    if [[ "$response" =~ ^[yY] ]]; then
        SELECTED_ITEMS=("${orphaned[@]}")
        execute_uninstall
    fi
}

cleanup_after_uninstall() {
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo apt autoremove -y >/dev/null 2>&1
            sudo apt autoclean >/dev/null 2>&1
            ;;
        "dnf"|"yum")
            sudo $PACKAGE_MANAGER autoremove -y >/dev/null 2>&1
            sudo $PACKAGE_MANAGER clean all >/dev/null 2>&1
            ;;
        "pacman"|"yay")
            yay -Sc --noconfirm >/dev/null 2>&1
            ;;
        "zypper")
            sudo zypper clean -a >/dev/null 2>&1
            ;;
    esac
}

# Helper function to toggle selection of applications
toggle_selection() {
    local app="$1"
    local found=false
    local new_selection=()
    
    # Check if app is already selected and remove it
    for sel in "${SELECTED_ITEMS[@]}"; do
        if [[ "$sel" == "$app" ]]; then
            found=true
            echo_info "Deselected: $app"
        else
            new_selection+=("$sel")
        fi
    done
    
    # If not found, add it to selection
    if [[ "$found" == false ]]; then
        SELECTED_ITEMS+=("$app")
        echo_info "Selected: $app"
    else
        SELECTED_ITEMS=("${new_selection[@]}")
    fi
    
    sleep 0.5
}
