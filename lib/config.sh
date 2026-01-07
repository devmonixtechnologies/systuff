#!/bin/bash

# Configuration management for System Administration Toolkit

# Load configuration file
load_config() {
    local config_file="${1:-$SCRIPT_DIR/config.conf}"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log "INFO" "Configuration loaded from $config_file"
        return 0
    else
        log "WARN" "Configuration file not found: $config_file"
        return 1
    fi
}

# Validate configuration
validate_config() {
    local errors=()
    
    # Check required directories
    local required_dirs=("$LOG_DIR" "$DATA_DIR" "$BACKUP_DIR" "$TEMP_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$SCRIPT_DIR/$dir" ]]; then
            mkdir -p "$SCRIPT_DIR/$dir"
            log "INFO" "Created directory: $dir"
        fi
    done
    
    # Validate numeric thresholds
    if ! [[ "$CPU_WARNING_THRESHOLD" =~ ^[0-9]+$ ]] || \
       ! [[ "$CPU_CRITICAL_THRESHOLD" =~ ^[0-9]+$ ]]; then
        errors+=("Invalid CPU threshold values")
    fi
    
    if ! [[ "$MEMORY_WARNING_THRESHOLD" =~ ^[0-9]+$ ]] || \
       ! [[ "$MEMORY_CRITICAL_THRESHOLD" =~ ^[0-9]+$ ]]; then
        errors+=("Invalid memory threshold values")
    fi
    
    # Validate network timeout
    if ! [[ "$NETWORK_TIMEOUT" =~ ^[0-9]+$ ]]; then
        errors+=("Invalid network timeout value")
    fi
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        log "ERROR" "Configuration validation failed"
        for error in "${errors[@]}"; do
            log "ERROR" "$error"
        done
        return 1
    fi
    
    log "INFO" "Configuration validation passed"
    return 0
}

# Get configuration value
get_config() {
    local key="$1"
    local default="${2:-}"
    
    # Try to get from environment variable first
    local env_value="${!key:-}"
    
    if [[ -n "$env_value" ]]; then
        echo "$env_value"
        return 0
    fi
    
    # Try to get from config file
    if [[ -f "$SCRIPT_DIR/config.conf" ]]; then
        local config_value=$(grep "^${key}=" "$SCRIPT_DIR/config.conf" | cut -d'=' -f2- | tr -d '"')
        if [[ -n "$config_value" ]]; then
            echo "$config_value"
            return 0
        fi
    fi
    
    # Return default value
    echo "$default"
}

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"
    local config_file="$SCRIPT_DIR/config.conf"
    
    # Backup original config
    cp "$config_file" "$config_file.bak" 2>/dev/null || true
    
    if grep -q "^${key}=" "$config_file"; then
        # Update existing key
        sed -i "s/^${key}=.*/${key}=${value}/" "$config_file"
    else
        # Add new key
        echo "${key}=${value}" >> "$config_file"
    fi
    
    log "INFO" "Configuration updated: $key=$value"
}

# Reset configuration to defaults
reset_config() {
    local config_file="$SCRIPT_DIR/config.conf"
    
    if [[ -f "$config_file" ]]; then
        mv "$config_file" "$config_file.$(date +%Y%m%d_%H%M%S).bak"
        log "INFO" "Configuration backed up and reset"
    fi
    
    # Create default configuration
    cat > "$config_file" << 'EOF'
# System Administration Toolkit Configuration File
# This file was automatically reset to defaults

# General Settings
TOOLKIT_VERSION="1.0"
TOOLKIT_NAME="System Administration Toolkit"
DEBUG_MODE=false
LOG_LEVEL="INFO"

# Paths and Directories
LOG_DIR="./logs"
DATA_DIR="./data"
BACKUP_DIR="./backups"
TEMP_DIR="./tmp"

# Logging Configuration
LOG_ROTATION=true
MAX_LOG_SIZE="10M"
MAX_LOG_FILES="5"
LOG_TIMESTAMP_FORMAT="%Y-%m-%d %H:%M:%S"

# System Monitoring Thresholds
CPU_WARNING_THRESHOLD=80
CPU_CRITICAL_THRESHOLD=90
MEMORY_WARNING_THRESHOLD=80
MEMORY_CRITICAL_THRESHOLD=90
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
LOAD_WARNING_THRESHOLD=2.0
LOAD_CRITICAL_THRESHOLD=4.0

# Network Settings
DEFAULT_NETWORK_INTERFACE="eth0"
NETWORK_TIMEOUT=5
PING_COUNT=4
SPEED_TEST_SERVER="auto"

# Backup Settings
DEFAULT_BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION=true
BACKUP_ENCRYPTION=false
BACKUP_EXCLUDE_PATTERNS="*.tmp *.log *.cache"

# Security Settings
ENABLE_SECURITY_SCAN=true
FAILED_LOGIN_ATTEMPTS_THRESHOLD=10
PORT_SCAN_ENABLED=true
MONITOR_SU_USAGE=true

# Performance Monitoring
PERFORMANCE_CHECK_INTERVAL=60
ENABLE_PROCESS_MONITORING=true
TOP_PROCESS_COUNT=10
MONITOR_NETWORK_TRAFFIC=true

# User Management
USER_ACTIVITY_LOG=true
LOGIN_MONITORING=true
SUDO_LOG_MONITORING=true

# Service Management
CRITICAL_SERVICES="ssh nginx apache2 mysql postgresql"
SERVICE_RESTART_ON_FAILURE=false
SERVICE_HEALTH_CHECK_INTERVAL=300

# Notification Settings
ENABLE_EMAIL_NOTIFICATIONS=false
EMAIL_SMTP_SERVER=""
EMAIL_SMTP_PORT="587"
EMAIL_USERNAME=""
EMAIL_PASSWORD=""
EMAIL_RECIPIENTS=""

# System Cleanup
ENABLE_AUTO_CLEANUP=false
CLEANUP_INTERVAL="daily"
TEMP_FILE_AGE_DAYS=7
LOG_FILE_AGE_DAYS=30
CACHE_CLEANUP_ENABLED=true

# Theme and Display
COLOR_OUTPUT=true
USE_UNICODE_SYMBOLS=true
PAGER_ENABLED=true
PROGRESS_BAR_ENABLED=true

# Advanced Settings
PARALLEL_PROCESSING=true
MAX_PARALLEL_JOBS=4
ENABLE_CACHING=true
CACHE_DURATION=300
EOF
    
    log "INFO" "Default configuration created"
}

# Export configuration
export_config() {
    local output_file="${1:-config_export.conf}"
    
    if [[ -f "$SCRIPT_DIR/config.conf" ]]; then
        cp "$SCRIPT_DIR/config.conf" "$output_file"
        log "INFO" "Configuration exported to $output_file"
        echo "Configuration exported to $output_file"
    else
        log "ERROR" "Configuration file not found"
        return 1
    fi
}

# Import configuration
import_config() {
    local input_file="$1"
    
    if [[ -f "$input_file" ]]; then
        cp "$input_file" "$SCRIPT_DIR/config.conf"
        log "INFO" "Configuration imported from $input_file"
        echo "Configuration imported from $input_file"
    else
        log "ERROR" "Import file not found: $input_file"
        return 1
    fi
}

# Show configuration
show_config() {
    local section="${1:-all}"
    
    echo "=== Current Configuration ==="
    
    case "$section" in
        "general")
            echo "Toolkit Version: $(get_config TOOLKIT_VERSION)"
            echo "Debug Mode: $(get_config DEBUG_MODE)"
            echo "Log Level: $(get_config LOG_LEVEL)"
            ;;
        "thresholds")
            echo "CPU Warning: $(get_config CPU_WARNING_THRESHOLD)%"
            echo "CPU Critical: $(get_config CPU_CRITICAL_THRESHOLD)%"
            echo "Memory Warning: $(get_config MEMORY_WARNING_THRESHOLD)%"
            echo "Memory Critical: $(get_config MEMORY_CRITICAL_THRESHOLD)%"
            echo "Disk Warning: $(get_config DISK_WARNING_THRESHOLD)%"
            echo "Disk Critical: $(get_config DISK_CRITICAL_THRESHOLD)%"
            ;;
        "network")
            echo "Default Interface: $(get_config DEFAULT_NETWORK_INTERFACE)"
            echo "Network Timeout: $(get_config NETWORK_TIMEOUT)s"
            echo "Ping Count: $(get_config PING_COUNT)"
            ;;
        "backup")
            echo "Retention Days: $(get_config DEFAULT_BACKUP_RETENTION_DAYS)"
            echo "Compression: $(get_config BACKUP_COMPRESSION)"
            echo "Encryption: $(get_config BACKUP_ENCRYPTION)"
            ;;
        "all"|*)
            cat "$SCRIPT_DIR/config.conf" | grep -v "^#" | grep -v "^$"
            ;;
    esac
}

# Check if feature is enabled
is_feature_enabled() {
    local feature="$1"
    local value=$(get_config "$feature")
    
    case "$value" in
        true|1|yes|on) return 0 ;;
        false|0|no|off) return 1 ;;
        *) return 1 ;;
    esac
}

# Get threshold value
get_threshold() {
    local metric="$1"
    local level="$2"
    
    case "$metric" in
        "cpu")
            case "$level" in
                "warning") echo "$(get_config CPU_WARNING_THRESHOLD)" ;;
                "critical") echo "$(get_config CPU_CRITICAL_THRESHOLD)" ;;
            esac
            ;;
        "memory")
            case "$level" in
                "warning") echo "$(get_config MEMORY_WARNING_THRESHOLD)" ;;
                "critical") echo "$(get_config MEMORY_CRITICAL_THRESHOLD)" ;;
            esac
            ;;
        "disk")
            case "$level" in
                "warning") echo "$(get_config DISK_WARNING_THRESHOLD)" ;;
                "critical") echo "$(get_config DISK_CRITICAL_THRESHOLD)" ;;
            esac
            ;;
        "load")
            case "$level" in
                "warning") echo "$(get_config LOAD_WARNING_THRESHOLD)" ;;
                "critical") echo "$(get_config LOAD_CRITICAL_THRESHOLD)" ;;
            esac
            ;;
    esac
}

# Export functions
export -f load_config validate_config get_config set_config reset_config
export -f export_config import_config show_config is_feature_enabled get_threshold
