#!/bin/bash

# Logging and error handling for System Administration Toolkit

# Logging levels
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["CRITICAL"]=4
)

# Initialize logging
init_logging() {
    local log_file="${1:-$LOG_FILE}"
    local log_level="${2:-INFO}"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$log_file")"
    
    # Set global log file
    LOG_FILE="$log_file"
    CURRENT_LOG_LEVEL="$log_level"
    
    # Initialize log file with header
    echo "=== System Administration Toolkit Log Started ===" >> "$LOG_FILE"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "Version: $(get_config TOOLKIT_VERSION)" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
}

# Enhanced logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local caller="${BASH_SOURCE[2]##*/}:${BASH_LINENO[1]}"
    
    # Check if we should log this level
    local current_level_num="${LOG_LEVELS[$CURRENT_LOG_LEVEL]:-1}"
    local message_level_num="${LOG_LEVELS[$level]:-1}"
    
    if [[ $message_level_num -lt $current_level_num ]]; then
        return 0
    fi
    
    # Write to log file
    echo "[$timestamp] [$level] [$caller] $message" >> "$LOG_FILE"
    
    # Output to console for errors and critical messages
    if [[ "$level" == "ERROR" || "$level" == "CRITICAL" ]]; then
        print_color "$RED" "$level: $message" >&2
    elif [[ "$level" == "WARN" ]]; then
        print_color "$YELLOW" "$level: $message" >&2
    fi
    
    # Send notification if enabled
    if is_feature_enabled "ENABLE_EMAIL_NOTIFICATIONS" && [[ "$level" == "ERROR" || "$level" == "CRITICAL" ]]; then
        send_notification "$level" "$message"
    fi
}

# Debug logging
log_debug() {
    log "DEBUG" "$@"
}

# Info logging
log_info() {
    log "INFO" "$@"
}

# Warning logging
log_warn() {
    log "WARN" "$@"
}

# Error logging
log_error() {
    log "ERROR" "$@"
}

# Critical logging
log_critical() {
    log "CRITICAL" "$@"
}

# Log command execution
log_command() {
    local command="$*"
    local start_time=$(date +%s)
    
    log_info "Executing command: $command"
    
    # Execute command and capture output
    local output
    local exit_code
    
    if output=$(eval "$command" 2>&1); then
        exit_code=0
        log_info "Command succeeded: $command"
    else
        exit_code=$?
        log_error "Command failed (exit code: $exit_code): $command"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "Command duration: ${duration}s"
    
    # Log output if verbose mode is enabled
    if is_feature_enabled "DEBUG_MODE"; then
        log_debug "Command output: $output"
    fi
    
    return $exit_code
}

# Log system event
log_system_event() {
    local event_type="$1"
    shift
    local details="$*"
    
    log_info "System Event [$event_type]: $details"
    
    # Store in database if enabled
    if is_feature_enabled "DATABASE_TYPE"; then
        store_system_event "$event_type" "$details"
    fi
}

# Log performance metrics
log_performance() {
    local metric_name="$1"
    local value="$2"
    local unit="${3:-}"
    
    log_info "Performance Metric: $metric_name=$value$unit"
    
    # Store in database if enabled
    if is_feature_enabled "DATABASE_TYPE"; then
        store_performance_metric "$metric_name" "$value" "$unit"
    fi
}

# Log security event
log_security_event() {
    local event_type="$1"
    shift
    local details="$*"
    
    log_warn "Security Event [$event_type]: $details"
    
    # Send immediate notification for security events
    if is_feature_enabled "ENABLE_EMAIL_NOTIFICATIONS"; then
        send_notification "SECURITY" "Security Event: $event_type - $details"
    fi
    
    # Store in security log
    local security_log="$LOG_DIR/security.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$event_type] $details" >> "$security_log"
}

# Error handling functions
handle_error() {
    local exit_code=$?
    local line_number=$1
    local bash_command="$2"
    
    log_error "Script failed at line $line_number: $bash_command (exit code: $exit_code)"
    
    # Cleanup on error
    cleanup_on_error
    
    # Send notification if enabled
    if is_feature_enabled "ENABLE_EMAIL_NOTIFICATIONS"; then
        send_notification "ERROR" "Script failed at line $line_number: $bash_command"
    fi
    
    exit $exit_code
}

# Set error trap
set_error_trap() {
    set -E
    trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR
}

# Cleanup function for error scenarios
cleanup_on_error() {
    log_info "Performing cleanup due to error..."
    
    # Remove temporary files
    if [[ -d "$TEMP_DIR" ]]; then
        find "$TEMP_DIR" -name "*.tmp" -type f -mtime +1 -delete 2>/dev/null || true
    fi
    
    # Kill background processes
    jobs -p | xargs -r kill 2>/dev/null || true
    
    log_info "Cleanup completed"
}

# Log rotation
rotate_logs() {
    local log_dir="${1:-$(dirname "$LOG_FILE")}"
    local max_size="${2:-$(get_config MAX_LOG_SIZE)}"
    local max_files="${3:-$(get_config MAX_LOG_FILES)}"
    
    if [[ ! -d "$log_dir" ]]; then
        return 0
    fi
    
    # Convert size to bytes
    local size_bytes
    case "$max_size" in
        *K|*k) size_bytes=$((${max_size%[Kk]} * 1024)) ;;
        *M|m) size_bytes=$((${max_size%[Mm]} * 1024 * 1024)) ;;
        *G|g) size_bytes=$((${max_size%[Gg]} * 1024 * 1024 * 1024)) ;;
        *) size_bytes="$max_size" ;;
    esac
    
    # Rotate each log file
    find "$log_dir" -name "*.log" -type f | while read log_file; do
        local file_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
        
        if [[ $file_size -gt $size_bytes ]]; then
            log_info "Rotating log file: $log_file"
            
            # Rotate existing logs
            for ((i=max_files; i>1; i--)); do
                local old_file="${log_file}.${i}"
                local new_file="${log_file}.$((i-1))"
                
                if [[ -f "$new_file" ]]; then
                    mv "$new_file" "$old_file"
                fi
            done
            
            # Move current log to .1
            mv "$log_file" "${log_file}.1"
            
            # Create new log file
            touch "$log_file"
            chmod 644 "$log_file"
            
            log_info "Log rotation completed for: $log_file"
        fi
    done
}

# Send notification (placeholder for email/SMS)
send_notification() {
    local level="$1"
    local message="$2"
    
    # This is a placeholder - implement actual notification system
    log_info "Notification [$level]: $message"
    
    # Example email implementation (requires mail command)
    if command -v mail &>/dev/null && is_feature_enabled "ENABLE_EMAIL_NOTIFICATIONS"; then
        local recipients=$(get_config EMAIL_RECIPIENTS)
        local subject="[$TOOLKIT_NAME] $level Alert"
        
        echo "$message" | mail -s "$subject" "$recipients" 2>/dev/null || true
    fi
}

# Create log report
generate_log_report() {
    local duration="${1:-24}"  # hours
    local output_file="${2:-$DATA_DIR/log_report.txt}"
    
    local since_time=$(date -d "$duration hours ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || \
                      date -v-${duration}H '+%Y-%m-%d %H:%M:%S' 2>/dev/null || \
                      date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$output_file" << EOF
=== Log Report ===
Generated: $(date '+%Y-%m-%d %H:%M:%S')
Period: Last $duration hours
Log File: $LOG_FILE

=== Summary ===
EOF
    
    # Count log levels
    if [[ -f "$LOG_FILE" ]]; then
        echo "Total entries: $(grep -c "\[$since_time\]" "$LOG_FILE" 2>/dev/null || echo 0)" >> "$output_file"
        echo "Errors: $(grep "\[$since_time\]" "$LOG_FILE" | grep -c "\[ERROR\]" 2>/dev/null || echo 0)" >> "$output_file"
        echo "Warnings: $(grep "\[$since_time\]" "$LOG_FILE" | grep -c "\[WARN\]" 2>/dev/null || echo 0)" >> "$output_file"
        echo "Critical: $(grep "\[$since_time\]" "$LOG_FILE" | grep -c "\[CRITICAL\]" 2>/dev/null || echo 0)" >> "$output_file"
        
        echo "" >> "$output_file"
        echo "=== Recent Errors ===" >> "$output_file"
        grep "\[$since_time\]" "$LOG_FILE" | grep "\[ERROR\]" | tail -10 >> "$output_file"
        
        echo "" >> "$output_file"
        echo "=== Recent Critical Events ===" >> "$output_file"
        grep "\[$since_time\]" "$LOG_FILE" | grep "\[CRITICAL\]" | tail -5 >> "$output_file"
    fi
    
    log_info "Log report generated: $output_file"
}

# Log analyzer
analyze_logs() {
    local pattern="$1"
    local log_file="${2:-$LOG_FILE}"
    
    if [[ ! -f "$log_file" ]]; then
        log_error "Log file not found: $log_file"
        return 1
    fi
    
    log_info "Analyzing logs for pattern: $pattern"
    
    echo "=== Log Analysis Results ==="
    echo "Pattern: $pattern"
    echo "Log File: $log_file"
    echo "Analysis Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "Match Count: $(grep -c "$pattern" "$log_file" 2>/dev/null || echo 0)"
    echo ""
    
    echo "Recent Matches:"
    grep "$pattern" "$log_file" | tail -10
    
    echo ""
    echo "Hourly Distribution:"
    grep "$pattern" "$log_file" | awk '{print $1}' | cut -d'[' -f1 | \
    awk '{split($1, a, ":"); hour = a[2]; count[hour]++} END {for (h in count) print h ":00", count[h]}' | \
    sort -n
}

# Export functions
export -f init_logging log log_debug log_info log_warn log_error log_critical
export -f log_command log_system_event log_performance log_security_event
export -f handle_error set_error_trap cleanup_on_error rotate_logs send_notification
export -f generate_log_report analyze_logs
