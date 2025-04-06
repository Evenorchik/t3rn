#!/bin/bash
#
# T3RN Executor Installation Script
# This script helps to install, update, configure and manage T3RN Executor node
# 
# Author: Evenorchik
# Version: 1.0.0
#

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Define paths
T3RN_CONFIG_DIR="$HOME/t3rn_config"
T3RN_DIR="$HOME/t3rn"
ENV_FILE="$T3RN_CONFIG_DIR/t3rn.env"
DEFAULT_RPC_FILE="$T3RN_CONFIG_DIR/default_rpc.conf"
CUSTOM_RPC_FILE="$T3RN_CONFIG_DIR/custom_rpc.conf"
SERVICE_FILE="/etc/systemd/system/t3rn.service"
TIMER_SERVICE_FILE="/etc/systemd/system/t3rn-restart.service"
TIMER_FILE="/etc/systemd/system/t3rn-restart.timer"

# Debug print to verify ENV_FILE path
echo "Debug: ENV_FILE path is $ENV_FILE"

# Function for displaying success messages
success_message() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# Function for displaying information messages
info_message() {
    echo -e "${CYAN}[i] $1${NC}"
}

# Function for displaying errors
error_message() {
    echo -e "${RED}[✗] $1${NC}"
}

# Function for displaying warnings
warning_message() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function for checking if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error_message "Command '$1' not found."
        return 1
    fi
    return 0
}

# Function for installing dependencies
install_dependencies() {
    info_message "Installing necessary packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget jq tar git make build-essential lz4 unzip
    success_message "Dependencies installed"
}

# Function to create default RPC configuration
create_default_rpc_config() {
    mkdir -p "$T3RN_CONFIG_DIR"
    cat > "$DEFAULT_RPC_FILE" << EOF
RPC_ENDPOINTS={"l2rn": ["https://t3rn-b2n.blockpi.network/v1/rpc/public", "https://b2n.rpc.caldera.xyz/http"],"arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],"bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],"blst": ["https://sepolia.blast.io", "https://endpoints.omniatech.io/v1/blast/sepolia/public"],"opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],"unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]}
EOF
    success_message "Default RPC configuration created"
}

# Function to initialize custom RPC file
initialize_custom_rpc_file() {
    if [ ! -f "$CUSTOM_RPC_FILE" ]; then
        echo "RPC_ENDPOINTS={}" > "$CUSTOM_RPC_FILE"
        success_message "Custom RPC configuration initialized"
    fi
}

# Function to fetch available versions
fetch_versions() {
    info_message "Fetching available versions from GitHub..."
    
    if ! check_command "curl"; then
        info_message "Installing curl..."
        sudo apt-get update && sudo apt-get install -y curl jq
    fi
    
    if ! check_command "jq"; then
        info_message "Installing jq..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
    
    # Fetch all releases from GitHub API and extract tag names, sort them by version (newest first)
    local versions=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases | jq -r '.[].tag_name' | sort -rV)
    
    if [ -z "$versions" ]; then
        error_message "Failed to fetch versions or no versions available."
        return 1
    fi
    
    echo "$versions"
}

# Function to update environment file
update_env_file() {
    local mode="$1"
    local private_key="$2"
    local max_gas="$3"
    local metrics_port="$4"
    
    mkdir -p "$T3RN_CONFIG_DIR"
    
    # Get RPC endpoints based on mode
    local rpc_endpoints
    
    if [ "$mode" = "rpc" ] && [ -f "$CUSTOM_RPC_FILE" ]; then
        # Read custom RPC config if available
        rpc_endpoints=$(grep "RPC_ENDPOINTS" "$CUSTOM_RPC_FILE" | cut -d'=' -f2-)
        # If custom RPC is empty, use default
        if [ "$rpc_endpoints" = "{}" ]; then
            rpc_endpoints=$(grep "RPC_ENDPOINTS" "$DEFAULT_RPC_FILE" | cut -d'=' -f2-)
        fi
    else
        # For API mode or if custom RPC not available, use default
        rpc_endpoints=$(grep "RPC_ENDPOINTS" "$DEFAULT_RPC_FILE" | cut -d'=' -f2-)
    fi
    
    # Create ENV file
    cat > "$ENV_FILE" << EOF
# T3RN Executor Configuration
# Generated on $(date)

# GENERAL SETTINGS
ENVIRONMENT=testnet
LOG_LEVEL=debug
LOG_PRETTY=false

# Process settings
EXECUTOR_PROCESS_BIDS_ENABLED=true
EXECUTOR_PROCESS_ORDERS_ENABLED=true
EXECUTOR_PROCESS_CLAIMS_ENABLED=true

# Max gas price (gwei)
EXECUTOR_MAX_L3_GAS_PRICE=$max_gas

# Metrics port
BIND_METRICS_PORT=$metrics_port

# API or RPC mode
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=$([ "$mode" = "api" ] && echo "true" || echo "false")

# Private key
PRIVATE_KEY_LOCAL=$private_key

# Enabled networks
ENABLED_NETWORKS='unichain-sepolia,blast-sepolia,arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'

# RPC endpoints - must be valid JSON without surrounding quotes
RPC_ENDPOINTS=$rpc_endpoints
EOF

    success_message "Environment file updated"
}

# Function to create systemd service
create_systemd_service() {
    local executor_path="$1"
    
    sudo bash -c "cat > '$SERVICE_FILE'" << EOF
[Unit]
Description=T3RN Executor Service
After=network.target

[Service]
User=$USER
EnvironmentFile=$ENV_FILE
ExecStart=$executor_path
WorkingDirectory=$(dirname "$executor_path")
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable t3rn
    success_message "Systemd service created"
}

# Function to create systemd timer
create_systemd_timer() {
    local hours="$1"
    
    # Remove existing timer if it exists
    remove_systemd_timer
    
    # Create service file for restart
    sudo bash -c "cat > '$TIMER_SERVICE_FILE'" << EOF
[Unit]
Description=Restart T3RN Executor Service

[Service]
Type=oneshot
ExecStart=/bin/systemctl restart t3rn.service

[Install]
WantedBy=multi-user.target
EOF

    # Create timer file
    sudo bash -c "cat > '$TIMER_FILE'" << EOF
[Unit]
Description=Restart T3RN Executor every $hours hours

[Timer]
OnBootSec=1min
OnUnitActiveSec=${hours}h

[Install]
WantedBy=timers.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable t3rn-restart.timer
    sudo systemctl start t3rn-restart.timer
    success_message "Systemd timer set to restart every $hours hours"
}

# Function to remove systemd timer
remove_systemd_timer() {
    if [ -f "$TIMER_FILE" ]; then
        sudo systemctl stop t3rn-restart.timer
        sudo systemctl disable t3rn-restart.timer
        sudo rm -f "$TIMER_FILE" "$TIMER_SERVICE_FILE"
        sudo systemctl daemon-reload
        success_message "Systemd timer removed"
    fi
}

# Function to download and install t3rn executor
install_t3rn() {
    local version="$1"
    local os_type="linux"  # Default to Linux
    
    # Create directory if it doesn't exist
    mkdir -p "$T3RN_DIR"
    cd "$T3RN_DIR"
    
    # Download the binary
    info_message "Downloading T3RN Executor version $version..."
    
    # GitHub uses the format: executor-linux-v0.56.0.tar.gz where version appears in both tag and filename
    wget "https://github.com/t3rn/executor-release/releases/download/$version/executor-$os_type-$version.tar.gz"
    
    if [ $? -ne 0 ]; then
        error_message "Failed to download T3RN Executor"
        return 1
    fi
    
    # Extract the archive
    info_message "Extracting archive..."
    tar -xzf "executor-$os_type-$version.tar.gz"
    
    if [ $? -ne 0 ]; then
        error_message "Failed to extract T3RN Executor"
        return 1
    fi
    
    # Navigate to the executor binary location
    cd executor/executor/bin
    
    # Check if the executor binary exists
    if [ ! -f "./executor" ]; then
        error_message "Executor binary not found"
        return 1
    fi
    
    # Make it executable
    chmod +x ./executor
    
    success_message "T3RN Executor installed successfully"
    echo "Executor binary location: $T3RN_DIR/executor/executor/bin/executor"
    
    return 0
}

# Function to start the t3rn service
start_t3rn() {
    info_message "Starting T3RN Executor service..."
    sudo systemctl start t3rn
    if [ $? -eq 0 ]; then
        success_message "T3RN Executor service started"
    else
        error_message "Failed to start T3RN Executor service"
    fi
}

# Function to stop the t3rn service
stop_t3rn() {
    info_message "Stopping T3RN Executor service..."
    sudo systemctl stop t3rn
    if [ $? -eq 0 ]; then
        success_message "T3RN Executor service stopped"
    else
        error_message "Failed to stop T3RN Executor service"
    fi
}

# Function to update t3rn
update_t3rn() {
    # Check if service is running
    if systemctl is-active --quiet t3rn; then
        stop_t3rn
    fi
    
    # Remove old installation but keep the timer configuration
    info_message "Removing old installation..."
    rm -rf "$T3RN_DIR"
    
    # Show version selection menu
    select_version_menu "update"
}

# Function to add custom RPC
add_custom_rpc() {
    info_message "Adding custom RPC endpoints..."
    
    # If the custom RPC file doesn't exist, initialize it
    initialize_custom_rpc_file
    
    # Define network codes and names (exclude l2rn)
    local networks=(
        "arbt:Arbitrum Sepolia"
        "bast:Base Sepolia"
        "blst:Blast Sepolia"
        "opst:Optimism Sepolia"
        "unit:Unichain Sepolia"
    )
    
    # Read current custom RPC config
    source "$CUSTOM_RPC_FILE"
    local current_rpc="$RPC_ENDPOINTS"
    
    # Remove the opening and closing brackets
    current_rpc="${current_rpc#\{}"
    current_rpc="${current_rpc%\}}"
    
    # Start building new RPC config
    # Automatically add the default l2rn endpoint from DEFAULT_RPC_FILE
    local l2rn_default=$(grep -o '"l2rn": *\[[^]]*\]' "$DEFAULT_RPC_FILE")
    local new_rpc="{ $l2rn_default"
    
    # If no l2rn config found in default, add a hardcoded one
    if [ -z "$l2rn_default" ]; then
        new_rpc="{ \"l2rn\": [\"https://t3rn-b2n.blockpi.network/v1/rpc/public\", \"https://b2n.rpc.caldera.xyz/http\"]" 
    fi
    
    # Loop through networks to get custom RPC (excluding l2rn)
    for network in "${networks[@]}"; do
        local code="${network%%:*}"
        local name="${network#*:}"
        
        echo -e "\n${YELLOW}Enter custom RPC for $name ($code) or leave empty to use default:${NC}"
        read -p "➜ " custom_rpc
        
        if [ -n "$custom_rpc" ]; then
            # Add to the new RPC config
            new_rpc="$new_rpc, \"$code\": [\"$custom_rpc\"]"
        fi
    done
    
    # Close the JSON object
    new_rpc="$new_rpc}"
    
    # Save to the custom RPC file
    echo "RPC_ENDPOINTS=$new_rpc" > "$CUSTOM_RPC_FILE"
    
    success_message "Custom RPC endpoints added"
    
    # Update the environment file if in RPC mode
    if grep -q "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false" "$ENV_FILE"; then
        local mode="rpc"
        local private_key=$(grep "PRIVATE_KEY_LOCAL" "$ENV_FILE" | cut -d'=' -f2)
        local max_gas=$(grep "EXECUTOR_MAX_L3_GAS_PRICE" "$ENV_FILE" | cut -d'=' -f2)
        local metrics_port=$(grep "BIND_METRICS_PORT" "$ENV_FILE" | cut -d'=' -f2)
        
        update_env_file "$mode" "$private_key" "$max_gas" "$metrics_port"
        
        # Restart the service to apply new settings
        if systemctl is-active --quiet t3rn; then
            restart_t3rn
        fi
    fi
}

# Function to reset RPC to defaults
reset_rpc() {
    info_message "Resetting RPC endpoints to defaults..."
    
    # If the custom RPC file exists, reset it
    if [ -f "$CUSTOM_RPC_FILE" ]; then
        echo "RPC_ENDPOINTS={}" > "$CUSTOM_RPC_FILE"
    fi
    
    # Update the environment file if in RPC mode
    if grep -q "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false" "$ENV_FILE"; then
        local mode="rpc"
        local private_key=$(grep "PRIVATE_KEY_LOCAL" "$ENV_FILE" | cut -d'=' -f2)
        local max_gas=$(grep "EXECUTOR_MAX_L3_GAS_PRICE" "$ENV_FILE" | cut -d'=' -f2)
        local metrics_port=$(grep "BIND_METRICS_PORT" "$ENV_FILE" | cut -d'=' -f2)
        
        update_env_file "$mode" "$private_key" "$max_gas" "$metrics_port"
        
        # Restart the service to apply new settings
        if systemctl is-active --quiet t3rn; then
            restart_t3rn
        fi
    fi
    
    success_message "RPC endpoints reset to defaults"
}

# Function to change gas settings
change_gas_settings() {
    info_message "Changing gas settings..."
    
    local current_gas=$(grep "EXECUTOR_MAX_L3_GAS_PRICE" "$ENV_FILE" | cut -d'=' -f2)
    echo -e "${YELLOW}Current max gas price: $current_gas gwei${NC}"
    echo -e "${YELLOW}Enter new max gas price (gwei):${NC}"
    read -p "➜ " new_gas
    
    # Validate input
    if ! [[ "$new_gas" =~ ^[0-9]+$ ]]; then
        error_message "Invalid input. Please enter a number."
        return 1
    fi
    
    # Update the environment file
    sed -i "s/EXECUTOR_MAX_L3_GAS_PRICE=.*/EXECUTOR_MAX_L3_GAS_PRICE=$new_gas/" "$ENV_FILE"
    
    success_message "Gas settings updated to $new_gas gwei"
    
    # Restart the service to apply new settings
    if systemctl is-active --quiet t3rn; then
        restart_t3rn
    fi
}

# Function to change private key
change_private_key() {
    info_message "Изменение приватного ключа..."
    
    local private_key=""
    local valid_key=false
    
    while [ "$valid_key" = false ]; do
        echo -e "${YELLOW}Введите новый приватный ключ (начинается с 0x):${NC}"
        read -p "➜ " private_key_input
        
        # Remove 0x prefix if present
        if [[ "$private_key_input" == 0x* ]]; then
            private_key="${private_key_input#0x}"
        else
            private_key="$private_key_input"
        fi
        
        # Validate private key
        if [ ${#private_key} -ne 64 ]; then
            error_message "Неверная длина приватного ключа. Должно быть 64 символа (без 0x). Попробуйте еще раз."
        else
            valid_key=true
        fi
    done
    
    # Update the environment file
    sed -i "s/PRIVATE_KEY_LOCAL=.*/PRIVATE_KEY_LOCAL=$private_key/" "$ENV_FILE"
    
    success_message "Приватный ключ обновлен"
    
    # Restart the service to apply new settings
    if systemctl is-active --quiet t3rn; then
        restart_t3rn
    fi
}

# Function to restart t3rn
restart_t3rn() {
    info_message "Restarting T3RN Executor service..."
    sudo systemctl restart t3rn
    if [ $? -eq 0 ]; then
        success_message "T3RN Executor service restarted"
    else
        error_message "Failed to restart T3RN Executor service"
    fi
}

# Function to view logs
view_logs() {
    info_message "Displaying T3RN Executor logs..."
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    sudo journalctl -u t3rn -f --no-hostname -o cat
}

# Function to show current config
show_config() {
    if [ ! -f "$ENV_FILE" ]; then
        error_message "Configuration file not found. Please install T3RN Executor first."
        return 1
    fi
    
    info_message "Current T3RN Executor Configuration:"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}"
    
    # Print general settings
    echo -e "${BOLD}${BLUE}General Settings:${NC}"
    grep -E "ENVIRONMENT|LOG_LEVEL|LOG_PRETTY" "$ENV_FILE" | while read line; do
        echo -e "${WHITE}$(echo $line | cut -d'=' -f1)${NC}=${GREEN}$(echo $line | cut -d'=' -f2)${NC}"
    done
    
    # Print process settings
    echo -e "\n${BOLD}${BLUE}Process Settings:${NC}"
    grep -E "EXECUTOR_PROCESS_BIDS_ENABLED|EXECUTOR_PROCESS_ORDERS_ENABLED|EXECUTOR_PROCESS_CLAIMS_ENABLED" "$ENV_FILE" | while read line; do
        echo -e "${WHITE}$(echo $line | cut -d'=' -f1)${NC}=${GREEN}$(echo $line | cut -d'=' -f2)${NC}"
    done
    
    # Print gas settings
    echo -e "\n${BOLD}${BLUE}Gas Settings:${NC}"
    grep "EXECUTOR_MAX_L3_GAS_PRICE" "$ENV_FILE" | while read line; do
        echo -e "${WHITE}$(echo $line | cut -d'=' -f1)${NC}=${GREEN}$(echo $line | cut -d'=' -f2) gwei${NC}"
    done
    
    # Print metrics port
    echo -e "\n${BOLD}${BLUE}Metrics Port:${NC}"
    grep "BIND_METRICS_PORT" "$ENV_FILE" | while read line; do
        echo -e "${WHITE}$(echo $line | cut -d'=' -f1)${NC}=${GREEN}$(echo $line | cut -d'=' -f2)${NC}"
    done
    
    # Print API/RPC mode
    echo -e "\n${BOLD}${BLUE}Mode:${NC}"
    if grep -q "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true" "$ENV_FILE"; then
        echo -e "${WHITE}Mode${NC}=${GREEN}API${NC}"
    else
        echo -e "${WHITE}Mode${NC}=${GREEN}RPC${NC}"
    fi
    
    # Print private key (masked)
    echo -e "\n${BOLD}${BLUE}Private Key:${NC}"
    local private_key=$(grep "PRIVATE_KEY_LOCAL" "$ENV_FILE" | cut -d'=' -f2)
    if [ -n "$private_key" ]; then
        echo -e "${WHITE}PRIVATE_KEY_LOCAL${NC}=${GREEN}$(echo $private_key | sed 's/\(^.\{4\}\).*\(.\{4\}$\)/\1****\2/')${NC}"
    else
        echo -e "${WHITE}PRIVATE_KEY_LOCAL${NC}=${RED}Not set${NC}"
    fi
    
    # Print enabled networks
    echo -e "\n${BOLD}${BLUE}Enabled Networks:${NC}"
    grep "ENABLED_NETWORKS" "$ENV_FILE" | while read line; do
        echo -e "${WHITE}$(echo $line | cut -d'=' -f1)${NC}=${GREEN}$(echo $line | cut -d'=' -f2)${NC}"
    done
    
    # Print timer settings if enabled
    if [ -f "$TIMER_FILE" ]; then
        echo -e "\n${BOLD}${BLUE}Auto-restart:${NC}"
        local hours=$(grep "OnUnitActiveSec" "$TIMER_FILE" | cut -d'=' -f2 | cut -d'h' -f1)
        echo -e "${WHITE}Restart interval${NC}=${GREEN}Every $hours hours${NC}"
    else
        echo -e "\n${BOLD}${BLUE}Auto-restart:${NC}"
        echo -e "${WHITE}Restart interval${NC}=${YELLOW}Not set${NC}"
    fi
    
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}"
}

# Function to remove t3rn
remove_t3rn() {
    info_message "Removing T3RN Executor..."
    
    # Stop the service if running
    if systemctl is-active --quiet t3rn; then
        stop_t3rn
    fi
    
    # Remove the timer if exists
    remove_systemd_timer
    
    # Disable and remove service
    if [ -f "$SERVICE_FILE" ]; then
        sudo systemctl disable t3rn
        sudo rm -f "$SERVICE_FILE"
        sudo systemctl daemon-reload
    fi
    
    # Remove directories
    rm -rf "$T3RN_DIR"
    rm -rf "$T3RN_CONFIG_DIR"
    
    success_message "T3RN Executor removed successfully"
}

# Function to change the running mode (API or RPC)
change_mode() {
    info_message "Changing running mode..."
    
    echo -e "${YELLOW}Select mode:${NC}"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}API Mode${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}RPC Mode${NC}"
    read -p "➜ " mode_choice
    
    case $mode_choice in
        1)
            # Update to API mode
            local mode="api"
            local private_key=$(grep "PRIVATE_KEY_LOCAL" "$ENV_FILE" | cut -d'=' -f2)
            local max_gas=$(grep "EXECUTOR_MAX_L3_GAS_PRICE" "$ENV_FILE" | cut -d'=' -f2)
            local metrics_port=$(grep "BIND_METRICS_PORT" "$ENV_FILE" | cut -d'=' -f2)
            
            update_env_file "$mode" "$private_key" "$max_gas" "$metrics_port"
            success_message "Mode changed to API"
            ;;
        2)
            # Update to RPC mode
            local mode="rpc"
            local private_key=$(grep "PRIVATE_KEY_LOCAL" "$ENV_FILE" | cut -d'=' -f2)
            local max_gas=$(grep "EXECUTOR_MAX_L3_GAS_PRICE" "$ENV_FILE" | cut -d'=' -f2)
            local metrics_port=$(grep "BIND_METRICS_PORT" "$ENV_FILE" | cut -d'=' -f2)
            
            update_env_file "$mode" "$private_key" "$max_gas" "$metrics_port"
            success_message "Mode changed to RPC"
            ;;
        *)
            error_message "Invalid choice"
            return 1
            ;;
    esac
    
    # Restart the service to apply new settings
    if systemctl is-active --quiet t3rn; then
        restart_t3rn
    fi
}

# Function to configure auto-restart
configure_restart() {
    info_message "Configuring auto-restart..."
    
    echo -e "${YELLOW}Select restart interval:${NC}"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}Every 4 hours${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}Every 12 hours${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}Every 24 hours${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}Every 72 hours${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}Disable auto-restart${NC}"
    read -p "➜ " restart_choice
    
    case $restart_choice in
        1)
            create_systemd_timer 4
            ;;
        2)
            create_systemd_timer 12
            ;;
        3)
            create_systemd_timer 24
            ;;
        4)
            create_systemd_timer 72
            ;;
        5)
            remove_systemd_timer
            ;;
        *)
            error_message "Invalid choice"
            return 1
            ;;
    esac
}

# Function for Configuration Menu
configuration_menu() {
    while true; do
        clear
        # Display logo
        curl -s https://raw.githubusercontent.com/Evenorchik/evenorlogo/refs/heads/main/evenorlogo.sh | bash
        
        echo -e "\n${BOLD}${WHITE}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
        echo -e "${BOLD}${WHITE}│      T3RN Executor Configuration       │${NC}"
        echo -e "${BOLD}${WHITE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}\n"
        
        echo -e "${BOLD}${BLUE}⚙️ Available options:${NC}\n"
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}Change mode (API/RPC)${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}Add custom RPC endpoints${NC}"
        echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}Reset RPC to defaults${NC}"
        echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}Change gas settings${NC}"
        echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}Change private key${NC}"
        echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}Configure auto-restart${NC}"
        echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}Restart service${NC}"
        echo -e "${WHITE}[${CYAN}8${WHITE}] ${GREEN}➜ ${WHITE}Stop service${NC}"
        echo -e "${WHITE}[${CYAN}9${WHITE}] ${GREEN}➜ ${WHITE}Start service${NC}"
        echo -e "${WHITE}[${CYAN}10${WHITE}] ${GREEN}➜ ${WHITE}Back to main menu${NC}\n"
        
        echo -e "${BOLD}${BLUE}📝 Enter option number [1-10]:${NC} "
        read -p "➜ " option
        
        case $option in
            1)
                change_mode
                ;;
            2)
                add_custom_rpc
                ;;
            3)
                reset_rpc
                ;;
            4)
                change_gas_settings
                ;;
            5)
                change_private_key
                ;;
            6)
                configure_restart
                ;;
            7)
                restart_t3rn
                ;;
            8)
                stop_t3rn
                ;;
            9)
                start_t3rn
                ;;
            10)
                return 0
                ;;
            *)
                error_message "Invalid option! Please enter a number from 1 to 10."
                ;;
        esac
        
        if [ "$option" != "10" ]; then
            echo -e "\nPress Enter to return to configuration menu..."
            read
        fi
    done
}

# Function for Installation Wizard
install_wizard() {
    local version="$1"
    
    clear
    # Display logo
    curl -s https://raw.githubusercontent.com/Evenorchik/evenorlogo/refs/heads/main/evenorlogo.sh | bash
    
    echo -e "\n${BOLD}${WHITE}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${BOLD}${WHITE}│     Installing T3RN Executor $version    │${NC}"
    echo -e "${BOLD}${WHITE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/7${WHITE}] ${GREEN}➜ ${WHITE}Installing dependencies...${NC}"
    install_dependencies
    
    echo -e "${WHITE}[${CYAN}2/7${WHITE}] ${GREEN}➜ ${WHITE}Creating configuration directories...${NC}"
    mkdir -p "$T3RN_CONFIG_DIR"
    create_default_rpc_config
    initialize_custom_rpc_file
    
    echo -e "${WHITE}[${CYAN}3/7${WHITE}] ${GREEN}➜ ${WHITE}Выберите режим работы ноды:${NC}"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}API Mode${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}RPC Mode${NC}"
    read -p "➜ " mode_choice
    
    local mode="api"
    if [ "$mode_choice" = "2" ]; then
        mode="rpc"
    fi
    
    if [ "$mode" = "api" ]; then
        local private_key=""
        local valid_key=false
        
        while [ "$valid_key" = false ]; do
            echo -e "${WHITE}[${CYAN}4/7${WHITE}] ${GREEN}➜ ${WHITE}Теперь введите ваш приватный ключ (начинается с 0x):${NC}"
            read -p "➜ " private_key_input
            
            # Remove 0x prefix if present
            if [[ "$private_key_input" == 0x* ]]; then
                private_key="${private_key_input#0x}"
            else
                private_key="$private_key_input"
            fi
            
            # Validate private key
            if [ ${#private_key} -ne 64 ]; then
                error_message "Неверная длина приватного ключа. Должно быть 64 символа (без 0x). Попробуйте еще раз."
            else
                valid_key=true
            fi
        done
    else
        echo -e "${WHITE}[${CYAN}4/7${WHITE}] ${GREEN}➜ ${WHITE}Выберите конфигурацию RPC:${NC}"
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}Использовать стандартные RPC-эндпоинты${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}Добавить собственные RPC-эндпоинты${NC}"
        read -p "➜ " rpc_choice
        
        if [ "$rpc_choice" = "2" ]; then
            add_custom_rpc
        fi
        
        local private_key=""
        local valid_key=false
        
        while [ "$valid_key" = false ]; do
            echo -e "${WHITE}[${CYAN}4/7${WHITE}] ${GREEN}➜ ${WHITE}Теперь введите ваш приватный ключ (начинается с 0x):${NC}"
            read -p "➜ " private_key_input
            
            # Remove 0x prefix if present
            if [[ "$private_key_input" == 0x* ]]; then
                private_key="${private_key_input#0x}"
            else
                private_key="$private_key_input"
            fi
            
            # Validate private key
            if [ ${#private_key} -ne 64 ]; then
                error_message "Неверная длина приватного ключа. Должно быть 64 символа (без 0x). Попробуйте еще раз."
            else
                valid_key=true
            fi
        done
    fi
    
    echo -e "${WHITE}[${CYAN}5/7${WHITE}] ${GREEN}➜ ${WHITE}Укажите максимальную цену газа в gwei [по умолчанию: 1000]:${NC}"
    read -p "➜ " max_gas
    
    if [ -z "$max_gas" ]; then
        max_gas=1000
    fi
    
    echo -e "${WHITE}[${CYAN}6/7${WHITE}] ${GREEN}➜ ${WHITE}Укажите порт для метрик [по умолчанию: 9090]:${NC}"
    read -p "➜ " metrics_port
    
    if [ -z "$metrics_port" ]; then
        metrics_port=9090
    fi
    
    # Update environment file
    update_env_file "$mode" "$private_key" "$max_gas" "$metrics_port"
    
    echo -e "${WHITE}[${CYAN}7/7${WHITE}] ${GREEN}➜ ${WHITE}Installing T3RN Executor...${NC}"
    
    # Install the T3RN Executor
    if install_t3rn "$version"; then
        # Create systemd service
        local executor_path="$T3RN_DIR/executor/executor/bin/executor"
        create_systemd_service "$executor_path"
        
        # Start the service
        start_t3rn
        
        echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✓ T3RN Executor successfully installed!${NC}"
        echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    fi
}

# Function to select version menu
select_version_menu() {
    local action="$1"
    local versions=$(fetch_versions)
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local i=1
    local latest=true
    local version_array=()
    
    echo -e "${YELLOW}Available versions:${NC}"
    while read -r version; do
        if [ $latest = true ]; then
            echo -e "${WHITE}[${CYAN}$i${WHITE}] ${GREEN}➜ ${WHITE}$version ${YELLOW}(latest)${NC}"
            latest=false
        else
            echo -e "${WHITE}[${CYAN}$i${WHITE}] ${GREEN}➜ ${WHITE}$version${NC}"
        fi
        version_array+=("$version")
        i=$((i+1))
    done <<< "$versions"
    
    echo -e "${WHITE}[${CYAN}$i${WHITE}] ${GREEN}➜ ${WHITE}Back to menu${NC}"
    
    read -p "➜ " choice
    
    if [ "$choice" -eq "$i" ]; then
        return 0
    elif [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
        local selected_version="${version_array[$((choice-1))]}"
        
        if [ "$action" = "install" ]; then
            install_wizard "$selected_version"
        elif [ "$action" = "update" ]; then
            # Install the selected version
            if install_t3rn "$selected_version"; then
                # Update the service file to point to the new binary
                local executor_path="$T3RN_DIR/executor/executor/bin/executor"
                create_systemd_service "$executor_path"
                start_t3rn
                success_message "T3RN Executor updated to version $selected_version"
            fi
        fi
    else
        error_message "Invalid choice"
        return 1
    fi
}

# Main function implementation
main() {
    while true; do
        clear
        # Display logo
        curl -s https://raw.githubusercontent.com/Evenorchik/evenorlogo/refs/heads/main/evenorlogo.sh | bash
        
        echo -e "\n${BOLD}${WHITE}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
        echo -e "${BOLD}${WHITE}│     Welcome to T3RN Executor Wizard    │${NC}"
        echo -e "${BOLD}${WHITE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}\n"
        
        echo -e "${BOLD}${BLUE}⚒️ Available actions:${NC}\n"
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}⚙️  Install node${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}📈  Update node${NC}"
        echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🔧  Configure node${NC}"
        echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}📊  View logs${NC}"
        echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}📋  Show current config${NC}"
        echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}♻️   Remove node${NC}"
        echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}🚶  Exit${NC}\n"
        
        echo -e "${BOLD}${BLUE}📝 Enter action number [1-7]:${NC} "
        read -p "➜ " choice
        
        case $choice in
            1)
                select_version_menu "install"
                ;;
            2)
                update_t3rn
                ;;
            3)
                if [ ! -f "$ENV_FILE" ]; then
                    error_message "T3RN Executor is not installed. Please install it first."
                else
                    configuration_menu
                fi
                ;;
            4)
                if [ ! -f "$ENV_FILE" ]; then
                    error_message "T3RN Executor is not installed. Please install it first."
                else
                    view_logs
                fi
                ;;
            5)
                show_config
                ;;
            6)
                if [ ! -f "$ENV_FILE" ]; then
                    error_message "T3RN Executor is not installed. Nothing to remove."
                else
                    remove_t3rn
                fi
                ;;
            7)
                echo -e "\n${GREEN}👋 Goodbye!${NC}\n"
                exit 0
                ;;
            *)
                error_message "Invalid choice! Please enter a number from 1 to 7."
                ;;
        esac
        
        if [ "$choice" != "4" ]; then
            echo -e "\nPress Enter to return to menu..."
            read
        fi
    done
}

# Запускаем основную функцию
main
