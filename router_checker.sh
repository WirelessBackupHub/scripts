#!/bin/bash
# Router File Service Checker
# Detects SMB and AFP services on local router (VPN-safe)

# Function to get router IP using DHCP info (VPN-safe)
get_router_ip() {
    # Get gateway from DHCP info for Wi-Fi
    local router_ip=$(ipconfig getoption en0 router 2>/dev/null)
    
    if [[ -n "$router_ip" ]]; then
        echo "$router_ip"
    else
        echo "ERROR: Could not determine router IP from DHCP"
        exit 1
    fi
}

# Test port connectivity
test_port() {
    local ip=$1
    local port=$2
    nc -z -w 3 "$ip" "$port" 2>/dev/null
    return $?
}

# Main execution
ROUTER_IP=$(get_router_ip)

if [[ $? -eq 0 ]]; then
    echo "Router IP: $ROUTER_IP"
    
    # Test SMB ports and determine version support
    port445=$(test_port "$ROUTER_IP" 445 && echo "true" || echo "false")
    port139=$(test_port "$ROUTER_IP" 139 && echo "true" || echo "false")
    
    if [[ "$port445" == "true" ]]; then
        smb_result="yes (v2+ supported)"
    elif [[ "$port139" == "true" ]]; then
        smb_result="yes (v1 only)"
    else
        smb_result="no"
    fi
    
    # Test AFP port (548)
    afp_result="no"
    if test_port "$ROUTER_IP" 548; then
        afp_result="yes"
    fi
    
    echo "SMB: $smb_result"
    echo "AFP: $afp_result"
fi