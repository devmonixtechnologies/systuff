#!/bin/bash

# System Administration Toolkit
# A comprehensive shell script utility for system management
# Author: DevMonix Technologies
# Version: 1.0

set -euo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
LOG_FILE="$SCRIPT_DIR/logs/toolkit.log"
DATA_DIR="$SCRIPT_DIR/data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize directories
init_directories() {
    mkdir -p "$DATA_DIR" "$(dirname "$LOG_FILE")"
}

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Print colored output
print_color() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_color "$RED" "This operation requires root privileges!"
        log "ERROR" "Root privileges required for operation"
        exit 1
    fi
}

# System information display
show_system_info() {
    print_color "$BLUE" "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Memory Usage:"
    free -h
    echo "Disk Usage:"
    df -h
    echo "CPU Info:"
    lscpu | grep "Model name\|CPU(s)\|Thread(s)"
    log "INFO" "System information displayed"
}

# Process monitoring
monitor_processes() {
    print_color "$BLUE" "=== Process Monitoring ==="
    echo "Top 10 CPU consuming processes:"
    ps aux --sort=-%cpu | head -11
    echo ""
    echo "Top 10 Memory consuming processes:"
    ps aux --sort=-%mem | head -11
    log "INFO" "Process monitoring completed"
}

# Service management
manage_services() {
    print_color "$BLUE" "=== Service Management ==="
    echo "Available services:"
    systemctl list-units --type=service --state=running | head -10
    
    echo ""
    read -p "Enter service name to check status: " service_name
    if systemctl is-active --quiet "$service_name"; then
        print_color "$GREEN" "Service $service_name is running"
    else
        print_color "$RED" "Service $service_name is not running"
    fi
    log "INFO" "Service management: $service_name"
}

# Network monitoring
monitor_network() {
    print_color "$BLUE" "=== Network Monitoring ==="
    echo "Active connections:"
    ss -tuln | head -10
    echo ""
    echo "Network interfaces:"
    ip addr show
    echo ""
    echo "Route table:"
    ip route
    log "INFO" "Network monitoring completed"
}

# Log analysis
analyze_logs() {
    print_color "$BLUE" "=== Log Analysis ==="
    local log_files=("/var/log/syslog" "/var/log/auth.log" "/var/log/kern.log")
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            echo "Recent entries from $log_file:"
            tail -5 "$log_file"
            echo ""
        fi
    done
    
    echo "Systemd journal errors (last 10):"
    journalctl -p err -n 10 --no-pager
    log "INFO" "Log analysis completed"
}

# Backup utility
create_backup() {
    print_color "$BLUE" "=== Backup Utility ==="
    read -p "Enter directory to backup: " backup_dir
    read -p "Enter backup destination: " backup_dest
    
    if [[ -d "$backup_dir" ]]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_file="$backup_dest/backup_$timestamp.tar.gz"
        
        mkdir -p "$backup_dest"
        tar -czf "$backup_file" "$backup_dir"
        
        print_color "$GREEN" "Backup created: $backup_file"
        log "INFO" "Backup created: $backup_file"
    else
        print_color "$RED" "Directory $backup_dir does not exist!"
        log "ERROR" "Backup failed - directory not found: $backup_dir"
    fi
}

# System cleanup
cleanup_system() {
    print_color "$BLUE" "=== System Cleanup ==="
    
    echo "Cleaning package cache..."
    if command -v apt &> /dev/null; then
        apt autoremove -y
        apt autoclean
    elif command -v yum &> /dev/null; then
        yum autoremove -y
        yum clean all
    elif command -v dnf &> /dev/null; then
        dnf autoremove -y
        dnf clean all
    fi
    
    echo "Cleaning temporary files..."
    find /tmp -type f -atime +7 -delete 2>/dev/null || true
    
    echo "Emptying trash..."
    rm -rf ~/.local/share/Trash/* 2>/dev/null || true
    
    print_color "$GREEN" "System cleanup completed"
    log "INFO" "System cleanup performed"
}

# Security scan
security_scan() {
    print_color "$BLUE" "=== Security Scan ==="
    
    echo "Checking for failed login attempts:"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 || echo "No failed attempts found or log not accessible"
    
    echo ""
    echo "Checking open ports:"
    ss -tuln | grep LISTEN
    
    echo ""
    echo "Checking user accounts:"
    awk -F: '($3 >= 1000) && ($1 != "nobody") {print $1}' /etc/passwd
    
    log "INFO" "Security scan completed"
}

# Performance monitoring
performance_monitor() {
    print_color "$BLUE" "=== Performance Monitoring ==="
    
    echo "CPU Load Average:"
    uptime
    
    echo ""
    echo "Memory Usage:"
    free -h
    
    echo ""
    echo "Disk I/O:"
    iostat -x 1 1 2>/dev/null || echo "iostat not available"
    
    echo ""
    echo "System load (1, 5, 15 minutes):"
    cat /proc/loadavg
    
    log "INFO" "Performance monitoring completed"
}

# User management
manage_users() {
    print_color "$BLUE" "=== User Management ==="
    
    echo "Current users:"
    who
    
    echo ""
    echo "System users:"
    awk -F: '($3 >= 1000) && ($1 != "nobody") {print $1, $6}' /etc/passwd
    
    echo ""
    read -p "Enter username to check details: " username
    if id "$username" &>/dev/null; then
        echo "User details for $username:"
        id "$username"
        finger "$username" 2>/dev/null || echo "Finger command not available"
    else
        print_color "$RED" "User $username does not exist"
    fi
    
    log "INFO" "User management: $username"
}

# Main menu
show_menu() {
    clear
    print_color "$GREEN" "=== System Administration Toolkit ==="
    echo "1. System Information"
    echo "2. Process Monitoring"
    echo "3. Service Management"
    echo "4. Network Monitoring"
    echo "5. Log Analysis"
    echo "6. Create Backup"
    echo "7. System Cleanup"
    echo "8. Security Scan"
    echo "9. Performance Monitoring"
    echo "10. User Management"
    echo "11. Exit"
    echo ""
}

# Main execution loop
main() {
    init_directories
    log "INFO" "System Administration Toolkit started"
    
    while true; do
        show_menu
        read -p "Select an option (1-11): " choice
        
        case $choice in
            1) show_system_info ;;
            2) monitor_processes ;;
            3) manage_services ;;
            4) monitor_network ;;
            5) analyze_logs ;;
            6) create_backup ;;
            7) 
                check_root
                cleanup_system 
                ;;
            8) security_scan ;;
            9) performance_monitor ;;
            10) manage_users ;;
            11) 
                print_color "$GREEN" "Goodbye!"
                log "INFO" "Toolkit exited by user"
                exit 0 
                ;;
            *) 
                print_color "$RED" "Invalid option. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in ss ip tar systemctl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_color "$RED" "Missing dependencies: ${missing_deps[*]}"
        print_color "$YELLOW" "Please install the missing commands and try again."
        exit 1
    fi
}

# Run checks and start
check_dependencies
main "$@"
