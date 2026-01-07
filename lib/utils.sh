#!/bin/bash

# Utility functions for System Administration Toolkit
# This file contains reusable functions

# Input validation
validate_input() {
    local input="$1"
    local pattern="$2"
    
    if [[ ! "$input" =~ $pattern ]]; then
        return 1
    fi
    return 0
}

# Check if directory exists and is writable
check_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        echo "Directory $dir does not exist"
        return 1
    fi
    
    if [[ ! -w "$dir" ]]; then
        echo "Directory $dir is not writable"
        return 1
    fi
    
    return 0
}

# Get file size in human readable format
get_file_size() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        du -h "$file" | cut -f1
    else
        echo "0"
    fi
}

# Convert bytes to human readable format
bytes_to_human() {
    local bytes=$1
    local units=('B' 'KB' 'MB' 'GB' 'TB')
    
    for unit in "${units[@]}"; do
        if (( bytes < 1024 )); then
            echo "${bytes} ${unit}"
            return
        fi
        bytes=$((bytes / 1024))
    done
    echo "${bytes} PB"
}

# Check internet connectivity
check_internet() {
    local test_sites=("8.8.8.8" "1.1.1.1" "google.com")
    
    for site in "${test_sites[@]}"; do
        if ping -c 1 -W 2 "$site" &>/dev/null; then
            return 0
        fi
    done
    return 1
}

# Get system load percentage
get_cpu_usage() {
    local load_avg=$(awk '{print $1}' /proc/loadavg)
    local cpu_cores=$(nproc)
    local usage=$(echo "$load_avg * 100 / $cpu_cores" | bc -l 2>/dev/null || echo "0")
    
    echo "${usage%.*}"
}

# Get memory usage percentage
get_memory_usage() {
    local mem_info=$(free | grep Mem)
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local usage=$((used * 100 / total))
    
    echo "$usage"
}

# Get disk usage percentage
get_disk_usage() {
    local path="${1:-/}"
    local usage=$(df "$path" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo "$usage"
}

# Check if service is installed
is_service_installed() {
    local service="$1"
    systemctl list-unit-files | grep -q "^${service}\.service"
}

# Get service status
get_service_status() {
    local service="$1"
    
    if systemctl is-active --quiet "$service"; then
        echo "running"
    elif systemctl is-enabled --quiet "$service"; then
        echo "stopped"
    else
        echo "disabled"
    fi
}

# Find large files
find_large_files() {
    local directory="${1:-/}"
    local min_size="${2:-100M}"
    
    find "$directory" -type f -size "+$min_size" -exec ls -lh {} \; 2>/dev/null | \
    awk '{print $5, $9}' | sort -hr | head -20
}

# Monitor file changes
monitor_file() {
    local file="$1"
    local duration="${2:-60}"
    
    if [[ ! -f "$file" ]]; then
        echo "File $file does not exist"
        return 1
    fi
    
    echo "Monitoring $file for $duration seconds..."
    inotifywait -m -e modify,create,delete "$file" &
    local monitor_pid=$!
    
    sleep "$duration"
    kill "$monitor_pid" 2>/dev/null
}

# Generate random password
generate_password() {
    local length="${1:-12}"
    local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*'
    
    echo "$(tr -dc "$chars" < /dev/urandom | head -c "$length")"
}

# Check password strength
check_password_strength() {
    local password="$1"
    local strength=0
    
    # Length check
    if [[ ${#password} -ge 8 ]]; then
        ((strength++))
    fi
    
    # Uppercase check
    if [[ "$password" =~ [A-Z] ]]; then
        ((strength++))
    fi
    
    # Lowercase check
    if [[ "$password" =~ [a-z] ]]; then
        ((strength++))
    fi
    
    # Number check
    if [[ "$password" =~ [0-9] ]]; then
        ((strength++))
    fi
    
    # Special character check
    if [[ "$password" =~ [!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?] ]]; then
        ((strength++))
    fi
    
    echo "$strength"
}

# Calculate file checksum
calculate_checksum() {
    local file="$1"
    local algorithm="${2:-sha256}"
    
    case "$algorithm" in
        md5) md5sum "$file" | awk '{print $1}' ;;
        sha1) sha1sum "$file" | awk '{print $1}' ;;
        sha256) sha256sum "$file" | awk '{print $1}' ;;
        sha512) sha512sum "$file" | awk '{print $1}' ;;
        *) echo "Unsupported algorithm: $algorithm"; return 1 ;;
    esac
}

# Verify file integrity
verify_file() {
    local file="$1"
    local expected_checksum="$2"
    local algorithm="${3:-sha256}"
    
    local actual_checksum=$(calculate_checksum "$file" "$algorithm")
    
    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        echo "File integrity verified"
        return 0
    else
        echo "File integrity check failed"
        echo "Expected: $expected_checksum"
        echo "Actual: $actual_checksum"
        return 1
    fi
}

# Get weather information (requires internet)
get_weather() {
    local location="${1:-}"
    local api_key="${2:-}"
    
    if [[ -z "$location" || -z "$api_key" ]]; then
        echo "Location and API key required for weather information"
        return 1
    fi
    
    if ! check_internet; then
        echo "No internet connection"
        return 1
    fi
    
    local url="http://api.openweathermap.org/data/2.5/weather?q=$location&appid=$api_key&units=metric"
    local response=$(curl -s "$url" 2>/dev/null)
    
    if [[ -n "$response" ]]; then
        echo "$response" | jq -r '.weather[0].description, .main.temp, .main.humidity' 2>/dev/null || \
        echo "Failed to parse weather data"
    else
        echo "Failed to fetch weather data"
    fi
}

# System health check
system_health_check() {
    local issues=()
    
    # Check disk space
    local disk_usage=$(get_disk_usage)
    if [[ $disk_usage -gt 90 ]]; then
        issues+=("Disk usage critical: ${disk_usage}%")
    elif [[ $disk_usage -gt 80 ]]; then
        issues+=("Disk usage high: ${disk_usage}%")
    fi
    
    # Check memory usage
    local mem_usage=$(get_memory_usage)
    if [[ $mem_usage -gt 90 ]]; then
        issues+=("Memory usage critical: ${mem_usage}%")
    elif [[ $mem_usage -gt 80 ]]; then
        issues+=("Memory usage high: ${mem_usage}%")
    fi
    
    # Check CPU usage
    local cpu_usage=$(get_cpu_usage)
    if [[ $cpu_usage -gt 90 ]]; then
        issues+=("CPU usage critical: ${cpu_usage}%")
    elif [[ $cpu_usage -gt 80 ]]; then
        issues+=("CPU usage high: ${cpu_usage}%")
    fi
    
    # Check load average
    local load_avg=$(awk '{print $1}' /proc/loadavg)
    local cpu_cores=$(nproc)
    if (( $(echo "$load_avg > $cpu_cores" | bc -l) )); then
        issues+=("Load average high: $load_avg")
    fi
    
    # Check internet connectivity
    if ! check_internet; then
        issues+=("No internet connectivity")
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        echo "System health: OK"
        return 0
    else
        echo "System health issues found:"
        printf '%s\n' "${issues[@]}"
        return 1
    fi
}

# Export functions for use in other scripts
export -f validate_input check_directory get_file_size bytes_to_human check_internet
export -f get_cpu_usage get_memory_usage get_disk_usage is_service_installed get_service_status
export -f find_large_files monitor_file generate_password check_password_strength
export -f calculate_checksum verify_file get_weather system_health_check
