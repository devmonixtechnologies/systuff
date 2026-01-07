#!/bin/bash

# Network utilities for System Administration Toolkit

# Get network interface information
get_network_interfaces() {
    ip -br addr show | while read interface status ip_info; do
        echo "Interface: $interface"
        echo "Status: $status"
        echo "IP: $ip_info"
        echo "---"
    done
}

# Check port status
check_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-3}"
    
    if timeout "$timeout" bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        echo "Port $port on $host is open"
        return 0
    else
        echo "Port $port on $host is closed or unreachable"
        return 1
    fi
}

# Scan open ports on local system
scan_local_ports() {
    echo "Scanning open ports on local system..."
    ss -tuln | awk 'NR>1 && $1 ~ /^(tcp|udp)/ {
        protocol = $1
        split($5, addr, ":")
        port = addr[length(addr)]
        printf "%-6s %-8s %s\n", protocol, port, $6
    }' | sort -k2 -n
}

# Get network statistics
get_network_stats() {
    local interfaces=($(ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' '))
    
    for interface in "${interfaces[@]}"; do
        if [[ "$interface" != "lo" ]]; then
            echo "Interface: $interface"
            cat "/proc/net/dev" | grep "$interface:" | \
            awk '{print "RX bytes: " $2 " (" $3 " packets)", "TX bytes: " $10 " (" $11 " packets)"}'
            echo ""
        fi
    done
}

# Monitor network traffic
monitor_network_traffic() {
    local interface="${1:-}"
    local duration="${2:-10}"
    
    if [[ -z "$interface" ]]; then
        echo "Available interfaces:"
        ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' ' | grep -v lo
        read -p "Enter interface name: " interface
    fi
    
    if ! ip link show "$interface" &>/dev/null; then
        echo "Interface $interface does not exist"
        return 1
    fi
    
    echo "Monitoring network traffic on $interface for $duration seconds..."
    
    local rx_start=$(cat "/proc/net/dev" | grep "$interface:" | awk '{print $2}')
    local tx_start=$(cat "/proc/net/dev" | grep "$interface:" | awk '{print $10}')
    
    sleep "$duration"
    
    local rx_end=$(cat "/proc/net/dev" | grep "$interface:" | awk '{print $2}')
    local tx_end=$(cat "/proc/net/dev" | grep "$interface:" | awk '{print $10}')
    
    local rx_diff=$((rx_end - rx_start))
    local tx_diff=$((tx_end - tx_start))
    
    echo "Traffic in $duration seconds:"
    echo "RX: $(bytes_to_human $rx_diff)"
    echo "TX: $(bytes_to_human $tx_diff)"
}

# Test network latency
test_latency() {
    local host="$1"
    local count="${2:-5}"
    
    if ping -c "$count" "$host" &>/dev/null; then
        local stats=$(ping -c "$count" "$host" 2>/dev/null | tail -1)
        echo "Latency to $host: $stats"
        return 0
    else
        echo "Host $host is unreachable"
        return 1
    fi
}

# Get public IP address
get_public_ip() {
    local services=("ifconfig.me" "ipinfo.io/ip" "icanhazip.com" "ident.me")
    
    for service in "${services[@]}"; do
        local ip=$(curl -s "$service" 2>/dev/null)
        if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    echo "Failed to get public IP"
    return 1
}

# Get DNS information
get_dns_info() {
    local domain="$1"
    
    echo "DNS information for $domain:"
    echo "A records:"
    dig +short "$domain" A 2>/dev/null || echo "No A records found"
    
    echo "MX records:"
    dig +short "$domain" MX 2>/dev/null || echo "No MX records found"
    
    echo "NS records:"
    dig +short "$domain" NS 2>/dev/null || echo "No NS records found"
    
    echo "TXT records:"
    dig +short "$domain" TXT 2>/dev/null || echo "No TXT records found"
}

# Check DNS resolution
check_dns_resolution() {
    local domain="$1"
    
    if nslookup "$domain" &>/dev/null; then
        echo "DNS resolution for $domain: OK"
        return 0
    else
        echo "DNS resolution for $domain: FAILED"
        return 1
    fi
}

# Get ARP table
get_arp_table() {
    echo "ARP table:"
    ip neigh show | while read ip dev interface mac state; do
        echo "IP: $ip, MAC: $mac, Interface: $interface, State: $state"
    done
}

# Flush ARP cache
flush_arp_cache() {
    if [[ $EUID -ne 0 ]]; then
        echo "Root privileges required to flush ARP cache"
        return 1
    fi
    
    ip -s -s neigh flush all
    echo "ARP cache flushed"
}

# Get routing table
get_routing_table() {
    echo "Routing table:"
    ip route show | while read route; do
        echo "$route"
    done
}

# Add static route
add_static_route() {
    local network="$1"
    local gateway="$2"
    local interface="${3:-}"
    
    if [[ $EUID -ne 0 ]]; then
        echo "Root privileges required to add static route"
        return 1
    fi
    
    if [[ -n "$interface" ]]; then
        ip route add "$network" via "$gateway" dev "$interface"
    else
        ip route add "$network" via "$gateway"
    fi
    
    echo "Static route added: $network via $gateway"
}

# Network speed test
network_speed_test() {
    local server="${1:-speedtest.net}"
    
    if ! command -v speedtest-cli &>/dev/null; then
        echo "speedtest-cli not installed. Install with: pip install speedtest-cli"
        return 1
    fi
    
    echo "Running network speed test..."
    speedtest-cli --simple
}

# Bandwidth monitoring
monitor_bandwidth() {
    local interface="${1:-}"
    local duration="${2:-60}"
    
    if [[ -z "$interface" ]]; then
        echo "Available interfaces:"
        ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' ' | grep -v lo
        read -p "Enter interface name: " interface
    fi
    
    if ! ip link show "$interface" &>/dev/null; then
        echo "Interface $interface does not exist"
        return 1
    fi
    
    echo "Monitoring bandwidth on $interface for $duration seconds..."
    
    local start_time=$(date +%s)
    local rx_bytes_start=$(cat "/proc/net/dev" | grep "$interface:" | awk '{print $2}')
    local tx_bytes_start=$(cat "/proc/net/dev" | grep "$interface:" | awk '{print $10}')
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [[ $elapsed -ge $duration ]]; then
            break
        fi
        
        sleep 1
        
        local rx_bytes_current=$(cat "/proc/net/dev" | grep "$interface:" | awk '{print $2}')
        local tx_bytes_current=$(cat "/proc/net/dev" | grep "$interface:" | awk '{print $10}')
        
        local rx_rate=$(((rx_bytes_current - rx_bytes_start) / elapsed))
        local tx_rate=$(((tx_bytes_current - tx_bytes_start) / elapsed))
        
        printf "\rRX: %s/s, TX: %s/s, Elapsed: %ds" \
            "$(bytes_to_human $rx_rate)" "$(bytes_to_human $tx_rate)" "$elapsed"
    done
    
    echo ""
}

# Check network interface status
check_interface_status() {
    local interface="$1"
    
    local status=$(ip link show "$interface" | grep -o 'state [A-Z]*' | cut -d' ' -f2)
    local carrier=$(cat "/sys/class/net/$interface/carrier" 2>/dev/null || echo "0")
    
    echo "Interface: $interface"
    echo "State: $status"
    echo "Carrier: $([[ $carrier == "1" ]] && echo "Connected" || echo "Disconnected")"
    
    if [[ "$status" == "UP" && "$carrier" == "1" ]]; then
        return 0
    else
        return 1
    fi
}

# Export functions
export -f get_network_interfaces check_port scan_local_ports get_network_stats
export -f monitor_network_traffic test_latency get_public_ip get_dns_info
export -f check_dns_resolution get_arp_table flush_arp_cache get_routing_table
export -f add_static_route network_speed_test monitor_bandwidth check_interface_status
