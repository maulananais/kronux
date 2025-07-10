#!/bin/bash

# KRONUX Actions
# Author: Maulana Nais
# Description: Action handlers for install, uninstall, and services

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

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
                pop_nav
                if [[ ${#NAV_STACK[@]} -gt 0 ]]; then
                    ${NAV_STACK[-1]}
                else
                    show_main_menu
                fi
                return
                ;;
            *)
                IFS=' ' read -ra SELECTIONS <<< "$selection"
                for sel in "${SELECTIONS[@]}"; do
                    if [[ "$sel" =~ ^[0-9]+$ ]] && [[ $sel -ge 0 && $sel -le ${#items[@]} ]]; then
                        if [[ $sel -eq 0 ]]; then 
                            SELECTED_ITEMS=()
                            pop_nav
                            if [[ ${#NAV_STACK[@]} -gt 0 ]]; then
                                ${NAV_STACK[-1]}
                            else
                                show_main_menu
                            fi
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
                pop_nav
                if [[ ${#NAV_STACK[@]} -gt 0 ]]; then
                    ${NAV_STACK[-1]}
                else
                    show_main_menu
                fi
                return
                ;;
            *)
                IFS=' ' read -ra SELECTIONS <<< "$selection"
                for sel in "${SELECTIONS[@]}"; do
                    if [[ "$sel" =~ ^[0-9]+$ ]] && [[ $sel -ge 0 && $sel -le ${#items[@]} ]]; then
                        if [[ $sel -eq 0 ]]; then 
                            UNINSTALL_SELECTED_ITEMS=(); pop_nav; ${NAV_STACK[-1]}; return
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

# Confirm and run action
confirm_and_run_action() {
    local action="$1"
    clear
    show_ascii_logo
    show_header "CONFIRM ${action^^}"
    
    echo_info "You are about to $action the following items:"
    for item in "${SELECTED_ITEMS[@]}"; do echo -e "  ${GREEN}•${NC} $item"; done
    
    echo_info "Package Manager: $PACKAGE_MANAGER"
    echo_info "Total Items: ${#SELECTED_ITEMS[@]}"
    
    echo -en "${YELLOW}${BOLD}Are you sure you want to $action these items? [y/N]:${NC} "
    read -r response
    
    if [[ ! "$response" =~ ^[yY] ]]; then
        echo_info "$action cancelled."; sleep 1; SELECTED_ITEMS=(); pop_nav; ${NAV_STACK[-1]}; return
    fi
    
    run_action "$action"
    SELECTED_ITEMS=()
    echo_success "$action completed!"
    pause_for_user
    pop_nav; ${NAV_STACK[-1]}
}

# Run action
run_action() {
    local action="$1"
    local success_count=0
    local failure_count=0
    
    for item in "${SELECTED_ITEMS[@]}"; do
        local pkg_name=$(get_package_name "$item")
        case "$action" in
            "Install")
                if install_package_with_check "$item" "$pkg_name"; then
                    ((success_count++))
                else
                    ((failure_count++))
                fi
                ;;
            "Uninstall")
                if uninstall_package_with_check "$item" "$pkg_name"; then
                    ((success_count++))
                else
                    ((failure_count++))
                fi
                ;;
            "Enable Service")
                if check_service_status "$item"; then
                    echo_warning "Service $item is already enabled"
                    log_action "SERVICE_ALREADY_ENABLED" "$item"
                    ((success_count++))
                else
                    echo_progress "Enabling service $item..."
                    if sudo systemctl enable "$item"; then
                        echo_success "Successfully enabled service $item"
                        log_action "ENABLE_SERVICE_SUCCESS" "$item"
                        ((success_count++))
                    else
                        echo_error "Failed to enable service $item"
                        log_action "ENABLE_SERVICE_FAILED" "$item"
                        ((failure_count++))
                    fi
                fi
                ;;
            "Disable Service")
                if ! check_service_status "$item"; then
                    echo_warning "Service $item is already disabled"
                    log_action "SERVICE_ALREADY_DISABLED" "$item"
                    ((success_count++))
                else
                    echo_progress "Disabling service $item..."
                    if sudo systemctl disable "$item"; then
                        echo_success "Successfully disabled service $item"
                        log_action "DISABLE_SERVICE_SUCCESS" "$item"
                        ((success_count++))
                    else
                        echo_error "Failed to disable service $item"
                        log_action "DISABLE_SERVICE_FAILED" "$item"
                        ((failure_count++))
                    fi
                fi
                ;;
        esac
    done
    
    # Show summary
    echo
    echo_info "=== OPERATION SUMMARY ==="
    echo_success "Successful operations: $success_count"
    if [[ $failure_count -gt 0 ]]; then
        echo_error "Failed operations: $failure_count"
    fi
    echo_info "Check logs at: $LOG_FILE"
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
        echo_info "Uninstall cancelled."; sleep 1; UNINSTALL_SELECTED_ITEMS=(); show_uninstall_module_menu; return
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
    show_uninstall_module_menu
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
