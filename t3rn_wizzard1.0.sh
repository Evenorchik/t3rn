#!/bin/bash

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

# Function for installing dependencies
install_dependencies() {
    info_message "Installing necessary packages..."
    sudo apt update && sudo apt-get upgrade -y
    sudo apt install -y git make jq build-essential gcc unzip wget curl tar
    success_message "Dependencies installed"
}

# Function for restarting the node service
restart_service() {
    info_message "Restarting T3rn Executor Node service..."
    sudo systemctl daemon-reload
    sudo systemctl restart t3rn-executor
    if sudo systemctl is-active --quiet t3rn-executor; then
        success_message "T3rn Executor Node service restarted successfully"
    else
        error_message "Failed to restart T3rn Executor Node service. Check logs for details."
    fi
}

# Check for curl and install if not present
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Clear screen
clear

# Function variables that will be set during installation
PRIVATE_KEY_LOCAL=""
INSTALLATION_MODE="" # Will be set to "api" or "rpc"

# Function for displaying welcome logo
display_logo() {
    clear
    # Display GitHub logo
    curl -s https://raw.githubusercontent.com/Evenorchik/evenorlogo/refs/heads/main/evenorlogo.sh | bash
    
    # Display node wizard title
    echo -e "\n${BOLD}${WHITE}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${BOLD}${WHITE}│      🔷 T3rn Executor Node Wizard      │${NC}"
    echo -e "${BOLD}${WHITE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}\n"
}

# Function for displaying menu
print_menu() {
    echo -e "${BOLD}${BLUE}⚒️ Available actions:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}⚙️  Install Node${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🔄  Update Node${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}⛽  Configure Gas Settings${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔌  Change RPC Endpoints${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🔧  Change Gas Settings${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🔑  Change Private Key${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}🔄  Toggle API/RPC Mode${NC}"
    echo -e "${WHITE}[${CYAN}8${WHITE}] ${GREEN}➜ ${WHITE}📊  Check Logs${NC}"
    echo -e "${WHITE}[${CYAN}9${WHITE}] ${GREEN}➜ ${WHITE}🔍  Display Current Settings${NC}"
    echo -e "${WHITE}[${CYAN}10${WHITE}] ${GREEN}➜ ${WHITE}♻️  Remove Node${NC}"
    echo -e "${WHITE}[${CYAN}11${WHITE}] ${GREEN}➜ ${WHITE}🚶  Exit${NC}\n"
}

# Function for RPC submenu
print_rpc_submenu() {
    echo -e "\n${BOLD}${WHITE}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${BOLD}${WHITE}│        🔌 Change RPC Endpoints         │${NC}"
    echo -e "${BOLD}${WHITE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}\n"
    
    echo -e "${BOLD}${BLUE}⚒️ Select network to change:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🔵  Arbitrum Sepolia${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🟢  Base Sepolia${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🟠  Blast Sepolia${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🟣  Unichain Sepolia${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🔴  Optimism Sepolia${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🧹  Clear RPC Settings${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}⬅️  Back to Main Menu${NC}\n"
}

# Function for choosing installation mode
choose_installation_mode() {
    echo -e "\n${BOLD}${WHITE}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${BOLD}${WHITE}│        🔄 Choose Processing Mode        │${NC}"
    echo -e "${BOLD}${WHITE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}\n"
    
    echo -e "${BOLD}${BLUE}⚒️ Select how you want to process orders:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🔌  Via API (Recommended for higher reliability)${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🌐  Via RPC (Requires manual RPC configuration)${NC}\n"
    
    echo -e "${BOLD}${BLUE}📝 Enter selection [1-2]:${NC} "
    read -p "➜ " mode_choice
    
    case $mode_choice in
        1)
            INSTALLATION_MODE="api"
            EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="true"
            success_message "API mode selected for processing orders"
            ;;
        2)
            INSTALLATION_MODE="rpc"
            EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="false"
            success_message "RPC mode selected for processing orders"
            ;;
        *)
            error_message "Invalid choice. Defaulting to API mode."
            INSTALLATION_MODE="api"
            EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="true"
            ;;
    esac
}

# Function for toggling between API and RPC mode
toggle_api_rpc_mode() {
    echo -e "\n${BOLD}${BLUE}🔄 Toggle between API and RPC processing mode...${NC}\n"
    
    # Check current mode
    if [ -f ~/t3rn/executor.env ]; then
        current_mode=$(grep "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API" ~/t3rn/executor.env | cut -d= -f2)
    else
        error_message "Environment file not found. Please install the node first."
        return
    fi
    
    if [ "$current_mode" = "true" ]; then
        echo -e "${YELLOW}Current mode: API processing${NC}"
        echo -e "${YELLOW}Do you want to switch to RPC processing? (y/n)${NC}"
        read -p "➜ " switch_choice
        
        if [[ "$switch_choice" =~ ^[Yy]$ ]]; then
            sed -i "s/EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true/EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false/" ~/t3rn/executor.env
            success_message "Switched to RPC processing mode"
            
            # Ask if user wants to configure RPC endpoints
            echo -e "${YELLOW}Do you want to configure RPC endpoints now? (y/n)${NC}"
            read -p "➜ " config_rpc
            
            if [[ "$config_rpc" =~ ^[Yy]$ ]]; then
                setup_rpc_endpoints
            fi
        else
            info_message "Keeping API processing mode"
        fi
    else
        echo -e "${YELLOW}Current mode: RPC processing${NC}"
        echo -e "${YELLOW}Do you want to switch to API processing? (y/n)${NC}"
        read -p "➜ " switch_choice
        
        if [[ "$switch_choice" =~ ^[Yy]$ ]]; then
            sed -i "s/EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false/EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true/" ~/t3rn/executor.env
            success_message "Switched to API processing mode"
        else
            info_message "Keeping RPC processing mode"
        fi
    fi
    
    # Restart service to apply changes
    restart_service
}

# Function for setting up private key
set_private_key() {
    echo -e "${YELLOW}🔑 Enter your private key (with '0x' prefix):${NC}"
    read -p "➜ " private_key
    echo
    
    if [ -z "$private_key" ]; then
        error_message "Private key cannot be empty"
        set_private_key
        return
    fi
    
    # Add 0x prefix if not present
    if [[ ! "$private_key" =~ ^0x ]]; then
        private_key="0x$private_key"
    fi
    
    # Update the global variable
    PRIVATE_KEY_LOCAL="$private_key"
    
    # If the node is already installed, update the env file directly
    if [ -f ~/t3rn/executor.env ]; then
        sed -i "s/^PRIVATE_KEY_LOCAL=.*/PRIVATE_KEY_LOCAL=$private_key/" ~/t3rn/executor.env
        success_message "Private key updated"
        
        # Restart service to apply changes
        restart_service
    else
        success_message "Private key set"
    fi
}

# Function for setting gas settings
set_gas_settings() {
    echo -e "\n${BOLD}${BLUE}⛽ Configure Gas Settings...${NC}\n"
    
    # Get gas settings from user
    echo -e "${YELLOW}🔢 Enter max L3 gas price (in GWEI) - controls when executor stops if gas rises above this level (default is 1000 GWEI):${NC}"
    read -p "➜ " max_gas_price
    
    echo -e "${YELLOW}🔢 Enter prometheus port (default is 9090, but use 9091 if 9090 is already in use):${NC}"
    read -p "➜ " prometheus_port
    
    # Validate input
    if [ -z "$max_gas_price" ]; then
        max_gas_price="1000"  # Default value from docs
        info_message "Using default max gas price: 1000 GWEI"
    fi
    
    if [ -z "$prometheus_port" ]; then
        prometheus_port="9091"  # Default to alternate port
        info_message "Using default prometheus port: 9091"
    fi
    
    # Create or update gas settings in environment file
    if [ -f ~/t3rn/executor.env ]; then
        # Update existing settings
        sed -i "s/^EXECUTOR_MAX_L3_GAS_PRICE=.*/EXECUTOR_MAX_L3_GAS_PRICE=$max_gas_price/" ~/t3rn/executor.env
        sed -i "s/^PROMETHEUS_PORT=.*/PROMETHEUS_PORT=$prometheus_port/" ~/t3rn/executor.env
        
        # Add settings if they don't exist
        if ! grep -q "EXECUTOR_MAX_L3_GAS_PRICE" ~/t3rn/executor.env; then
            echo "EXECUTOR_MAX_L3_GAS_PRICE=$max_gas_price" >> ~/t3rn/executor.env
        fi
        
        if ! grep -q "PROMETHEUS_PORT" ~/t3rn/executor.env; then
            echo "PROMETHEUS_PORT=$prometheus_port" >> ~/t3rn/executor.env
        fi
        success_message "Gas settings updated"
        
        # Restart service to apply changes
        restart_service
    else
        # Create environment file with gas settings
        mkdir -p ~/t3rn
        cat > ~/t3rn/executor.env << EOF
ENVIRONMENT=testnet
LOG_LEVEL=debug
LOG_PRETTY=false
EXECUTOR_PROCESS_BIDS_ENABLED=true
EXECUTOR_PROCESS_ORDERS_ENABLED=true
EXECUTOR_PROCESS_CLAIMS_ENABLED=true
PRIVATE_KEY_LOCAL=${PRIVATE_KEY_LOCAL}
ENABLED_NETWORKS=blast-sepolia,unichain-sepolia,arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn
EXECUTOR_MAX_L3_GAS_PRICE=$max_gas_price
PROMETHEUS_PORT=$prometheus_port
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=${EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API:-true}
EOF
        success_message "Gas settings created"
    fi
}

# Function for changing gas settings
change_gas_settings() {
    set_gas_settings
}

# Function for setting up RPC endpoints for each network
setup_rpc_endpoints() {
    echo -e "${WHITE}[${CYAN}4/6${WHITE}] ${GREEN}➜ ${WHITE}🔌 Setting up RPC endpoints...${NC}"
    
    # Define networks and their codes
    declare -A networks=(
        ["Arbitrum Sepolia"]="arbt"
        ["Base Sepolia"]="bast"
        ["Blast Sepolia"]="blst"
        ["Unichain Sepolia"]="unit"
        ["Optimism Sepolia"]="opst"
    )
    
    # Initialize default RPC endpoints JSON
    if [ -z "$RPC_ENDPOINTS" ]; then
        RPC_ENDPOINTS='{
            "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
            "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
            "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
            "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
            "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"],
            "blst": ["https://sepolia.blast.io", "https://endpoints.omniatech.io/v1/blast/sepolia/public"]
        }'
    fi
    
    # Extract current RPC endpoints if env file exists
    if [ -f ~/t3rn/executor.env ] && grep -q "RPC_ENDPOINTS" ~/t3rn/executor.env; then
        rpc_line=$(grep "RPC_ENDPOINTS" ~/t3rn/executor.env)
        # Use proper JSON extraction
        rpc_json=$(echo "$rpc_line" | sed -E "s/RPC_ENDPOINTS='(.*)'/\1/")
        if echo "$rpc_json" | jq empty &>/dev/null; then
            RPC_ENDPOINTS="$rpc_json"
            info_message "Successfully loaded existing RPC configuration"
        else
            warning_message "Could not parse existing RPC configuration, using defaults"
        fi
    fi
    
    # For each network, ask for custom RPC
    for network in "${!networks[@]}"; do
        code=${networks[$network]}
        echo -e "${YELLOW}🔌 Enter additional RPC endpoint for ${network} (press Enter to skip):${NC}"
        read -p "➜ " new_rpc
        
        if [ -n "$new_rpc" ]; then
            # Add the new RPC to the array using temporary file to avoid quoting issues
            echo "$RPC_ENDPOINTS" > /tmp/rpc_temp.json
            if jq -e ".$code" /tmp/rpc_temp.json &>/dev/null; then
                # Network exists in JSON
                if ! jq -e ".$code | index(\"$new_rpc\")" /tmp/rpc_temp.json &>/dev/null; then
                    # RPC doesn't exist, add it
                    RPC_ENDPOINTS=$(jq ".$code += [\"$new_rpc\"]" /tmp/rpc_temp.json)
                    success_message "Added RPC endpoint for ${network}"
                else
                    info_message "This RPC endpoint is already in the list"
                fi
            else
                # Network doesn't exist, create it
                RPC_ENDPOINTS=$(jq ".$code = [\"$new_rpc\"]" /tmp/rpc_temp.json)
                success_message "Added RPC endpoint for ${network}"
            fi
            rm /tmp/rpc_temp.json
        else
            info_message "Using default RPC endpoints for ${network}"
        fi
    done
    
    # If the node is already installed, update the env file directly
    if [ -f ~/t3rn/executor.env ]; then
        # Create temporary file to store properly formatted JSON
        echo "$RPC_ENDPOINTS" > /tmp/rpc_formatted.json
        # Make sure the JSON is valid
        if jq empty /tmp/rpc_formatted.json &>/dev/null; then
            # Use awk to replace the line because sed struggles with complex JSON
            awk -v rpc="$(cat /tmp/rpc_formatted.json)" '{
                if (/^RPC_ENDPOINTS=/) {
                    print "RPC_ENDPOINTS=\x27" rpc "\x27"
                } else {
                    print $0
                }
            }' ~/t3rn/executor.env > ~/t3rn/executor.env.new
            mv ~/t3rn/executor.env.new ~/t3rn/executor.env
            success_message "RPC endpoints updated"
            
            # Restart service to apply changes
            restart_service
        else
            error_message "Invalid JSON format. RPC endpoints not updated."
        fi
        rm /tmp/rpc_formatted.json
    fi
}

# Function for changing RPC endpoints
change_rpc() {
    local network_code=""
    local network_name=""
    
    case $1 in
        1)
            network_code="arbt"
            network_name="Arbitrum Sepolia"
            ;;
        2)
            network_code="bast"
            network_name="Base Sepolia"
            ;;
        3)
            network_code="blst"
            network_name="Blast Sepolia"
            ;;
        4)
            network_code="unit"
            network_name="Unichain Sepolia"
            ;;
        5)
            network_code="opst"
            network_name="Optimism Sepolia"
            ;;
        *)
            error_message "Invalid selection"
            return
            ;;
    esac
    
    echo -e "\n${BOLD}${BLUE}🔌 Changing RPC for ${network_name}...${NC}\n"
    
    # Extract current RPC endpoints
    local current_rpc='{}'
    if [ -f ~/t3rn/executor.env ] && grep -q "RPC_ENDPOINTS" ~/t3rn/executor.env; then
        rpc_line=$(grep "RPC_ENDPOINTS" ~/t3rn/executor.env)
        # Use proper JSON extraction
        rpc_json=$(echo "$rpc_line" | sed -E "s/RPC_ENDPOINTS='(.*)'/\1/")
        if echo "$rpc_json" | jq empty &>/dev/null; then
            current_rpc="$rpc_json"
            info_message "Successfully loaded existing RPC configuration"
        else
            warning_message "Could not parse existing RPC configuration, using defaults"
        fi
    fi
    
    # Get new RPC endpoint from user
    echo -e "${YELLOW}🔢 Enter new RPC endpoint for ${network_name}:${NC}"
    read -p "➜ " new_rpc
    
    # Validate input
    if [ -z "$new_rpc" ]; then
        error_message "RPC endpoint cannot be empty"
        return
    fi
    
    # Add the new RPC using temporary file to avoid quoting issues
    echo "$current_rpc" > /tmp/rpc_temp.json
    
    if jq -e ".$network_code" /tmp/rpc_temp.json &>/dev/null; then
        # Network exists in JSON
        if ! jq -e ".$network_code | index(\"$new_rpc\")" /tmp/rpc_temp.json &>/dev/null; then
            # RPC doesn't exist, add it
            updated_rpc=$(jq ".$network_code += [\"$new_rpc\"]" /tmp/rpc_temp.json)
            success_message "Added RPC endpoint for ${network_name}"
        else
            info_message "This RPC endpoint is already in the list"
            rm /tmp/rpc_temp.json
            return
        fi
    else
        # Network doesn't exist, create it
        updated_rpc=$(jq ".$network_code = [\"$new_rpc\"]" /tmp/rpc_temp.json)
        success_message "Added RPC endpoint for ${network_name}"
    fi
    
    rm /tmp/rpc_temp.json
    
    # Update the environment file
    if [ -f ~/t3rn/executor.env ]; then
        # Create temporary file to store properly formatted JSON
        echo "$updated_rpc" > /tmp/rpc_formatted.json
        # Make sure the JSON is valid
        if jq empty /tmp/rpc_formatted.json &>/dev/null; then
            # Use awk to replace the line
            awk -v rpc="$(cat /tmp/rpc_formatted.json)" '{
                if (/^RPC_ENDPOINTS=/) {
                    print "RPC_ENDPOINTS=\x27" rpc "\x27"
                } else {
                    print $0
                }
            }' ~/t3rn/executor.env > ~/t3rn/executor.env.new
            mv ~/t3rn/executor.env.new ~/t3rn/executor.env
            success_message "RPC endpoint for ${network_name} updated"
            
            # Restart service to apply changes
            restart_service
        else
            error_message "Invalid JSON format. RPC endpoints not updated."
        fi
        rm /tmp/rpc_formatted.json
    else
        RPC_ENDPOINTS="$updated_rpc"
        success_message "RPC endpoint for ${network_name} will be applied on next install"
    fi
}

# Function for clearing RPC settings
clear_rpc_settings() {
    echo -e "\n${BOLD}${BLUE}🧹 Clearing RPC endpoints settings...${NC}\n"
    
    echo -e "${YELLOW}⚠️ This will reset all RPC endpoints to default values.${NC}"
    echo -e "${YELLOW}Are you sure you want to continue? (y/n)${NC}"
    read -p "➜ " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Default RPC endpoints from official documentation
        default_rpc='{
            "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
            "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
            "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
            "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
            "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"],
            "blst": ["https://sepolia.blast.io", "https://endpoints.omniatech.io/v1/blast/sepolia/public"]
        }'
        
        # Update environment file with default RPC
        if [ -f ~/t3rn/executor.env ]; then
            # Save default JSON to temp file
            echo "$default_rpc" > /tmp/default_rpc.json
            
            # Use awk to replace the line
            awk -v rpc="$(cat /tmp/default_rpc.json)" '{
                if (/^RPC_ENDPOINTS=/) {
                    print "RPC_ENDPOINTS=\x27" rpc "\x27"
                } else {
                    print $0
                }
            }' ~/t3rn/executor.env > ~/t3rn/executor.env.new
            mv ~/t3rn/executor.env.new ~/t3rn/executor.env
            
            rm /tmp/default_rpc.json
            
            success_message "RPC endpoints reset to default values"
            
            # Restart service to apply changes
            restart_service
        else
            RPC_ENDPOINTS="$default_rpc"
            success_message "Default RPC endpoints will be applied on next install"
        fi
    else
        info_message "Operation canceled"
    fi
}

# Function for checking logs
check_logs() {
    echo -e "\n${BOLD}${BLUE}📊 Checking T3rn Executor Node logs...${NC}\n"
    sudo journalctl -u t3rn-executor -f --no-hostname
}

# Function to display current settings
display_current_settings() {
    echo -e "\n${BOLD}${WHITE}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${BOLD}${WHITE}│        🔍 Current Node Settings         │${NC}"
    echo -e "${BOLD}${WHITE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}\n"
    
    if [ ! -f ~/t3rn/executor.env ]; then
        error_message "Node is not installed yet. No settings available."
        return
    fi
    
    # Read from environment file
    echo -e "${BOLD}${BLUE}📋 General Settings:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────${NC}"
    
    # Processing mode
    if grep -q "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true" ~/t3rn/executor.env; then
        echo -e "${WHITE}Processing Mode:${NC} ${GREEN}API Mode${NC} (Recommended for higher reliability)"
    else
        echo -e "${WHITE}Processing Mode:${NC} ${YELLOW}RPC Mode${NC} (Using custom RPC endpoints)"
    fi
    
    # Environment
    if grep -q "ENVIRONMENT" ~/t3rn/executor.env; then
        env_value=$(grep "ENVIRONMENT" ~/t3rn/executor.env | cut -d= -f2)
        echo -e "${WHITE}Environment:${NC} ${GREEN}$env_value${NC}"
    fi
    
    # Logging
    if grep -q "LOG_LEVEL" ~/t3rn/executor.env; then
        log_level=$(grep "LOG_LEVEL" ~/t3rn/executor.env | cut -d= -f2)
        echo -e "${WHITE}Log Level:${NC} ${GREEN}$log_level${NC}"
    fi
    
    # Enabled Networks
    if grep -q "ENABLED_NETWORKS" ~/t3rn/executor.env; then
        networks=$(grep "ENABLED_NETWORKS" ~/t3rn/executor.env | cut -d= -f2)
        echo -e "${WHITE}Enabled Networks:${NC} ${GREEN}$networks${NC}"
    fi
    
    echo -e "\n${BOLD}${BLUE}⛽ Gas Settings:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────${NC}"
    
    # Max Gas Price
    if grep -q "EXECUTOR_MAX_L3_GAS_PRICE" ~/t3rn/executor.env; then
        gas_price=$(grep "EXECUTOR_MAX_L3_GAS_PRICE" ~/t3rn/executor.env | cut -d= -f2)
        echo -e "${WHITE}Max L3 Gas Price:${NC} ${GREEN}$gas_price${NC} GWEI"
    else
        echo -e "${WHITE}Max L3 Gas Price:${NC} ${YELLOW}Not Set${NC} (Will use default)"
    fi
    
    # Prometheus Port
    if grep -q "PROMETHEUS_PORT" ~/t3rn/executor.env; then
        prom_port=$(grep "PROMETHEUS_PORT" ~/t3rn/executor.env | cut -d= -f2)
        echo -e "${WHITE}Prometheus Port:${NC} ${GREEN}$prom_port${NC}"
    fi
    
    echo -e "\n${BOLD}${BLUE}🔄 Process Settings:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────${NC}"
    
    # Processing settings
    if grep -q "EXECUTOR_PROCESS_BIDS_ENABLED=true" ~/t3rn/executor.env; then
        echo -e "${WHITE}Process Bids:${NC} ${GREEN}Enabled${NC}"
    else
        echo -e "${WHITE}Process Bids:${NC} ${RED}Disabled${NC}"
    fi
    
    if grep -q "EXECUTOR_PROCESS_ORDERS_ENABLED=true" ~/t3rn/executor.env; then
        echo -e "${WHITE}Process Orders:${NC} ${GREEN}Enabled${NC}"
    else
        echo -e "${WHITE}Process Orders:${NC} ${RED}Disabled${NC}"
    fi
    
    if grep -q "EXECUTOR_PROCESS_CLAIMS_ENABLED=true" ~/t3rn/executor.env; then
        echo -e "${WHITE}Process Claims:${NC} ${GREEN}Enabled${NC}"
    else
        echo -e "${WHITE}Process Claims:${NC} ${RED}Disabled${NC}"
    fi
    
    echo -e "\n${BOLD}${BLUE}🔌 RPC Endpoints:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────${NC}"
    
    # RPC Endpoints (only show if in RPC mode)
    if ! grep -q "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true" ~/t3rn/executor.env; then
        if grep -q "RPC_ENDPOINTS" ~/t3rn/executor.env; then
            echo -e "${YELLOW}RPC Endpoints Configuration:${NC}"
            # Извлекаем строку с RPC_ENDPOINTS, сохраняя кавычки и форматирование
            rpc_line=$(grep "RPC_ENDPOINTS" ~/t3rn/executor.env)
            
            # Показываем весь JSON для отладки
            echo -e "${CYAN}Raw RPC configuration:${NC}\n$rpc_line"
                
            # Пытаемся извлечь и обработать JSON
            rpc_json=$(echo "$rpc_line" | sed -E "s/RPC_ENDPOINTS='(.*)'/\1/")
        
            # Проверяем валидность JSON с помощью jq
            if echo "$rpc_json" | jq empty &>/dev/null; then
                echo -e "${GREEN}Successfully parsed RPC configuration:${NC}"
                echo -e "${WHITE}Arbitrum Sepolia:${NC} $(echo "$rpc_json" | jq -r '.arbt | join(", ")' 2>/dev/null || echo "${YELLOW}Not configured${NC}")"
                echo -e "${WHITE}Base Sepolia:${NC} $(echo "$rpc_json" | jq -r '.bast | join(", ")' 2>/dev/null || echo "${YELLOW}Not configured${NC}")"
                echo -e "${WHITE}Blast Sepolia:${NC} $(echo "$rpc_json" | jq -r '.blst | join(", ")' 2>/dev/null || echo "${YELLOW}Not configured${NC}")"
                echo -e "${WHITE}Unichain Sepolia:${NC} $(echo "$rpc_json" | jq -r '.unit | join(", ")' 2>/dev/null || echo "${YELLOW}Not configured${NC}")"
                echo -e "${WHITE}Optimism Sepolia:${NC} $(echo "$rpc_json" | jq -r '.opst | join(", ")' 2>/dev/null || echo "${YELLOW}Not configured${NC}")"
                echo -e "${WHITE}Layer2rn:${NC} $(echo "$rpc_json" | jq -r '.l2rn | join(", ")' 2>/dev/null || echo "${YELLOW}Not configured${NC}")"
            else
                echo -e "${RED}Failed to parse RPC configuration as JSON. Raw content:${NC}\n$rpc_json"
            fi
        else
            echo -e "${YELLOW}No custom RPC endpoints found in configuration file.${NC}"
        fi
    else
        echo -e "${YELLOW}Node is in API mode. RPC endpoints are still configured but orders are processed via API:${NC}"
    fi
    
    echo -e "\n${BOLD}${BLUE}🚦 Service Status:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────${NC}"
    if sudo systemctl is-active --quiet t3rn-executor; then
        echo -e "${WHITE}Service Status:${NC} ${GREEN}Active${NC}"
        uptime=$(sudo systemctl show t3rn-executor --property=ActiveEnterTimestamp | cut -d= -f2)
        echo -e "${WHITE}Running Since:${NC} ${GREEN}$uptime${NC}"
    else
        echo -e "${WHITE}Service Status:${NC} ${RED}Inactive${NC}"
    fi
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}ℹ️ To view detailed logs use:${NC} ${CYAN}sudo journalctl -u t3rn-executor -f --no-hostname${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════════════════════════════${NC}\n"
}

# Function for installing the node
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Installing T3rn Executor Node...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/7${WHITE}] ${GREEN}➜ ${WHITE}🔄 Choose processing mode (API or RPC)...${NC}"
    choose_installation_mode

    echo -e "${WHITE}[${CYAN}2/7${WHITE}] ${GREEN}➜ ${WHITE}⚒️ Installing dependencies...${NC}"
    install_dependencies

    echo -e "${WHITE}[${CYAN}3/7${WHITE}] ${GREEN}➜ ${WHITE}📥 Downloading and setting up the node...${NC}"
    # Create and navigate to t3rn directory
    mkdir -p ~/t3rn
    cd ~/t3rn
    
    # Download latest release
    info_message "Downloading the latest T3rn executor release..."
    LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    wget -q https://github.com/t3rn/executor-release/releases/download/${LATEST_TAG}/executor-linux-${LATEST_TAG}.tar.gz
    
    # Extract the archive
    info_message "Extracting files..."
    tar -xzf executor-linux-*.tar.gz
    
    # Set default environment variables based on documentation
    ENVIRONMENT="testnet"
    LOG_LEVEL="debug"
    LOG_PRETTY="false"
    EXECUTOR_PROCESS_BIDS_ENABLED="true"
    EXECUTOR_PROCESS_ORDERS_ENABLED="true"
    EXECUTOR_PROCESS_CLAIMS_ENABLED="true"
    ENABLED_NETWORKS="blast-sepolia,unichain-sepolia,arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn"
    
    # Default RPC endpoints from official documentation
    RPC_ENDPOINTS='{
        "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
        "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
        "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
        "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
        "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"],
        "blst": ["https://sepolia.blast.io", "https://endpoints.omniatech.io/v1/blast/sepolia/public"]
    }'
    
    echo -e "${WHITE}[${CYAN}4/7${WHITE}] ${GREEN}➜ ${WHITE}🔑 Setting up private key...${NC}"
    set_private_key
    
    # Setup RPC endpoints only if RPC mode is selected
    if [ "$INSTALLATION_MODE" = "rpc" ]; then
        echo -e "${WHITE}[${CYAN}5/7${WHITE}] ${GREEN}➜ ${WHITE}🔌 Setting up RPC endpoints...${NC}"
        setup_rpc_endpoints
    else
        info_message "Skipping RPC configuration as API mode is selected"
    fi
    
    echo -e "${WHITE}[${CYAN}6/7${WHITE}] ${GREEN}➜ ${WHITE}⛽ Setting up gas settings...${NC}"
    set_gas_settings
    
    # Create the environment file
    echo -e "${WHITE}[${CYAN}7/7${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Creating environment file...${NC}"
    cat > ~/t3rn/executor.env << EOF
ENVIRONMENT=${ENVIRONMENT}
LOG_LEVEL=${LOG_LEVEL}
LOG_PRETTY=${LOG_PRETTY}
EXECUTOR_PROCESS_BIDS_ENABLED=${EXECUTOR_PROCESS_BIDS_ENABLED}
EXECUTOR_PROCESS_ORDERS_ENABLED=${EXECUTOR_PROCESS_ORDERS_ENABLED}
EXECUTOR_PROCESS_CLAIMS_ENABLED=${EXECUTOR_PROCESS_CLAIMS_ENABLED}
PRIVATE_KEY_LOCAL=${PRIVATE_KEY_LOCAL}
ENABLED_NETWORKS=${ENABLED_NETWORKS}
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=${EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API}
EOF

    # Add RPC endpoints in both modes, as they're needed for basic functionality
    # Save RPC JSON to temp file for proper quoting
    echo "$RPC_ENDPOINTS" > /tmp/install_rpc.json
    echo "RPC_ENDPOINTS='$(cat /tmp/install_rpc.json)'" >> ~/t3rn/executor.env
    rm /tmp/install_rpc.json

    
    # Add gas settings
    echo "PROMETHEUS_PORT=9091" >> ~/t3rn/executor.env
    if [ -n "$max_gas_price" ]; then
        echo "EXECUTOR_MAX_L3_GAS_PRICE=$max_gas_price" >> ~/t3rn/executor.env
    else
        echo "EXECUTOR_MAX_L3_GAS_PRICE=1000" >> ~/t3rn/executor.env
    fi
    
    success_message "Environment file created at ~/t3rn/executor.env"
    
    # Create systemd service
    echo -e "${WHITE}[${CYAN}7/7${WHITE}] ${GREEN}➜ ${WHITE}▶️ Creating and starting systemd service...${NC}"
    
    # Define current user name and home directory
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)
    
    # Create service file with environment variables from the env file
    sudo bash -c "cat > /etc/systemd/system/t3rn-executor.service << EOF
[Unit]
Description=T3rn Executor Node
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/t3rn/executor/executor/bin
EnvironmentFile=$HOME_DIR/t3rn/executor.env
ExecStart=$HOME_DIR/t3rn/executor/executor/bin/executor
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF"

    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable t3rn-executor
    sudo systemctl start t3rn-executor
    
    # Check if service started successfully
    if sudo systemctl is-active --quiet t3rn-executor; then
        success_message "T3rn Executor Node service started successfully"
    else
        error_message "Failed to start T3rn Executor Node service. Check logs for details."
    fi
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ T3rn Executor Node successfully installed and started!${NC}"
    if [ "$INSTALLATION_MODE" = "api" ]; then
        echo -e "${YELLOW}ℹ️ Node is configured to process orders via API for higher reliability${NC}"
    else
        echo -e "${YELLOW}ℹ️ Node is configured to process orders via RPC${NC}"
    fi
    echo -e "${YELLOW}ℹ️ To check node logs, run:${NC} ${CYAN}sudo journalctl -u t3rn-executor -f --no-hostname${NC}"
    if grep -q "PROMETHEUS_PORT=9091" ~/t3rn/executor.env; then
        echo -e "${YELLOW}ℹ️ Node is using port 9091 for Prometheus metrics${NC}"
    else
        echo -e "${YELLOW}ℹ️ Node is using default Prometheus port. If you have port conflicts, run option 3 to change it.${NC}"
    fi
    echo -e "${PURPLE}═════════════════════════════════════════════════════════════════════${NC}\n"
}

# Function for updating the node
update_node() {
    echo -e "\n${BOLD}${BLUE}🔄 Updating T3rn Executor Node...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/7${WHITE}] ${GREEN}➜ ${WHITE}🔄 Checking current mode...${NC}"
    # Determine if node is using API or RPC mode
    if [ -f ~/t3rn/executor.env ]; then
        current_mode=$(grep "EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API" ~/t3rn/executor.env | cut -d= -f2)
        if [ "$current_mode" = "true" ]; then
            INSTALLATION_MODE="api"
            EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="true"
            info_message "Current mode: API processing"
        else
            INSTALLATION_MODE="rpc"
            EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="false"
            info_message "Current mode: RPC processing"
        fi
    else
        echo -e "${YELLOW}Do you want to use API mode for processing orders? (y/n)${NC}"
        read -p "➜ " api_choice
        
        if [[ "$api_choice" =~ ^[Yy]$ ]]; then
            INSTALLATION_MODE="api"
            EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="true"
        else
            INSTALLATION_MODE="rpc"
            EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="false"
        fi
    fi

    echo -e "${WHITE}[${CYAN}2/7${WHITE}] ${GREEN}➜ ${WHITE}⚒️ Installing dependencies...${NC}"
    install_dependencies

    echo -e "${WHITE}[${CYAN}3/7${WHITE}] ${GREEN}➜ ${WHITE}♻️ Backing up configuration...${NC}"
    # Backup the environment file
    if [ -f ~/t3rn/executor.env ]; then
        cp ~/t3rn/executor.env ~/t3rn/executor.env.backup
        success_message "Environment file backed up"
        
        # Extract private key from backup
        PRIVATE_KEY_LOCAL=$(grep "PRIVATE_KEY_LOCAL" ~/t3rn/executor.env.backup | cut -d= -f2)
    fi
    
    # Remove old files
    echo -e "${WHITE}[${CYAN}4/7${WHITE}] ${GREEN}➜ ${WHITE}♻️ Removing old files...${NC}"
    rm -rf ~/t3rn/executor
    rm -rf ~/t3rn/executor-linux-*.tar.gz
    success_message "Old files removed"

    echo -e "${WHITE}[${CYAN}5/7${WHITE}] ${GREEN}➜ ${WHITE}📥 Downloading and setting up the node...${NC}"
    cd ~/t3rn
    
    # Download latest release
    info_message "Downloading the latest T3rn executor release..."
    LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    wget -q https://github.com/t3rn/executor-release/releases/download/${LATEST_TAG}/executor-linux-${LATEST_TAG}.tar.gz
    
    # Extract the archive
    info_message "Extracting files..."
    tar -xzf executor-linux-*.tar.gz
    
    echo -e "${WHITE}[${CYAN}6/7${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Restoring configuration...${NC}"
    # If we had an existing configuration, restore relevant settings
    if [ -f ~/t3rn/executor.env.backup ]; then
        info_message "Restoring settings from previous configuration"
        
        # If private key wasn't extracted, ask for it again
        if [ -z "$PRIVATE_KEY_LOCAL" ]; then
            echo -e "${WHITE}[${CYAN}6.1/7${WHITE}] ${GREEN}➜ ${WHITE}🔑 Setting up private key...${NC}"
            set_private_key
        else
            success_message "Private key restored from backup"
        fi
        
        # Restore max gas price if it exists
        if grep -q "EXECUTOR_MAX_L3_GAS_PRICE" ~/t3rn/executor.env.backup; then
            max_gas_price=$(grep "EXECUTOR_MAX_L3_GAS_PRICE" ~/t3rn/executor.env.backup | cut -d= -f2)
            success_message "Gas price settings restored from backup"
        else
            max_gas_price="1000"  # Default value
        fi
        
        # Restore prometheus port if it exists
        if grep -q "PROMETHEUS_PORT" ~/t3rn/executor.env.backup; then
            prometheus_port=$(grep "PROMETHEUS_PORT" ~/t3rn/executor.env.backup | cut -d= -f2)
            success_message "Prometheus port settings restored from backup"
        else
            prometheus_port="9091"  # Default value
        fi
        
        # Restore networks if they exist
        if grep -q "ENABLED_NETWORKS" ~/t3rn/executor.env.backup; then
            ENABLED_NETWORKS=$(grep "ENABLED_NETWORKS" ~/t3rn/executor.env.backup | cut -d= -f2)
            success_message "Network settings restored from backup"
        else
            ENABLED_NETWORKS="blast-sepolia,unichain-sepolia,arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn"
        fi
        
        # Restore RPC endpoints if RPC mode is selected and they exist in backup
        if [ "$INSTALLATION_MODE" = "rpc" ] && grep -q "RPC_ENDPOINTS" ~/t3rn/executor.env.backup; then
            RPC_ENDPOINTS=$(grep "RPC_ENDPOINTS" ~/t3rn/executor.env.backup | sed "s/RPC_ENDPOINTS='//" | sed "s/'$//")
            success_message "RPC endpoints restored from backup"
        fi
    else
        # If no backup, we need to set the private key
        if [ -z "$PRIVATE_KEY_LOCAL" ]; then
            echo -e "${WHITE}[${CYAN}6.1/7${WHITE}] ${GREEN}➜ ${WHITE}🔑 Setting up private key...${NC}"
            set_private_key
        fi
        
        # Set default values
        max_gas_price="1000"
        prometheus_port="9091"
        ENABLED_NETWORKS="blast-sepolia,unichain-sepolia,arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn"
        
        # Default RPC endpoints if in RPC mode
        if [ "$INSTALLATION_MODE" = "rpc" ]; then
            RPC_ENDPOINTS='{
                "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
                "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
                "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
                "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
                "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"],
                "blst": ["https://sepolia.blast.io", "https://endpoints.omniatech.io/v1/blast/sepolia/public"]
            }'
        fi
    fi
    
    # Create the environment file
    echo -e "${WHITE}[${CYAN}7/7${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Creating updated environment file...${NC}"
    cat > ~/t3rn/executor.env << EOF
ENVIRONMENT=testnet
LOG_LEVEL=debug
LOG_PRETTY=false
EXECUTOR_PROCESS_BIDS_ENABLED=true
EXECUTOR_PROCESS_ORDERS_ENABLED=true
EXECUTOR_PROCESS_CLAIMS_ENABLED=true
PRIVATE_KEY_LOCAL=${PRIVATE_KEY_LOCAL}
ENABLED_NETWORKS=${ENABLED_NETWORKS}
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=${EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API}
EOF

    # Add RPC endpoints in both modes, as they're needed for basic functionality
    # Save RPC JSON to temp file for proper quoting
    echo "$RPC_ENDPOINTS" > /tmp/update_rpc.json
    echo "RPC_ENDPOINTS='$(cat /tmp/update_rpc.json)'" >> ~/t3rn/executor.env
    rm /tmp/update_rpc.json
    
    # Add gas settings
    echo "PROMETHEUS_PORT=${prometheus_port}" >> ~/t3rn/executor.env
    echo "EXECUTOR_MAX_L3_GAS_PRICE=${max_gas_price}" >> ~/t3rn/executor.env
    
    success_message "Environment file updated at ~/t3rn/executor.env"
    
    # Create systemd service
    echo -e "${WHITE}[${CYAN}7/7${WHITE}] ${GREEN}➜ ${WHITE}▶️ Restarting systemd service...${NC}"
    
    # Define current user name and home directory
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)
    
    # Update service file with new path to the updated binary
    sudo bash -c "cat > /etc/systemd/system/t3rn-executor.service << EOF
[Unit]
Description=T3rn Executor Node
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/t3rn/executor/executor/bin
EnvironmentFile=$HOME_DIR/t3rn/executor.env
ExecStart=$HOME_DIR/t3rn/executor/executor/bin/executor
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF"

    # Reload and restart service
    sudo systemctl daemon-reload
    sudo systemctl restart t3rn-executor
    
    # Check if service started successfully
    if sudo systemctl is-active --quiet t3rn-executor; then
        success_message "T3rn Executor Node service started successfully"
    else
        error_message "Failed to start T3rn Executor Node service. Check logs for details."
    fi
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ T3rn Executor Node successfully updated and started!${NC}"
    if [ "$INSTALLATION_MODE" = "api" ]; then
        echo -e "${YELLOW}ℹ️ Node is configured to process orders via API for higher reliability${NC}"
    else
        echo -e "${YELLOW}ℹ️ Node is configured to process orders via RPC${NC}"
    fi
    echo -e "${YELLOW}ℹ️ To check node logs, run:${NC} ${CYAN}sudo journalctl -u t3rn-executor -f --no-hostname${NC}"
    if [ "$prometheus_port" = "9091" ]; then
        echo -e "${YELLOW}ℹ️ Node is using port 9091 for Prometheus metrics${NC}"
    else
        echo -e "${YELLOW}ℹ️ Node is using custom Prometheus port: ${prometheus_port}${NC}"
    fi
    echo -e "${PURPLE}═════════════════════════════════════════════════════════════════════${NC}\n"
}

# Function for removing the node
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Removing T3rn Executor Node...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}⏹️ Stopping service...${NC}"
    # Stop and remove service
    sudo systemctl stop t3rn-executor
    sudo systemctl disable t3rn-executor
    sudo rm /etc/systemd/system/t3rn-executor.service
    sudo systemctl daemon-reload
    success_message "Service stopped and removed"

    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}♻️ Removing node files...${NC}"
    # Remove node directory
    rm -rf ~/t3rn
    success_message "Node files removed"
    
    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🧹 Cleaning up environment...${NC}"
    # Remove any leftover files
    rm -f ~/t3rn-executor-*.log
    success_message "Environment cleaned"

    echo -e "\n${PURPLE}═════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ T3rn Executor Node successfully removed from system!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════════════════════════════${NC}\n"
}

# Main program loop
while true; do
    display_logo
    print_menu
    echo -e "${BOLD}${BLUE}📝 Enter action number [1-10]:${NC} "
    read -p "➜ " choice

    case $choice in
    1)
        install_node
        ;;
    2)
        update_node
        ;;
    3)
        set_gas_settings
        ;;
    4)
        while true; do
            display_logo
            print_rpc_submenu
            echo -e "${BOLD}${BLUE}📝 Enter selection [1-7]:${NC} "
            read -p "➜ " rpc_choice
            
            case $rpc_choice in
                1|2|3|4|5)
                    change_rpc "$rpc_choice"
                    echo -e "\nPress Enter to return to RPC menu..."
                    read
                    ;;
                6)
                    clear_rpc_settings
                    echo -e "\nPress Enter to return to RPC menu..."
                    read
                    ;;
                7)
                    break
                    ;;
                *)
                    error_message "Invalid choice! Please enter a number from 1 to 7."
                    echo -e "\nPress Enter to continue..."
                    read
                    ;;
            esac
        done
        ;;
    5)
        change_gas_settings
        ;;
    6)
        set_private_key
        ;;
    7)
        toggle_api_rpc_mode
        ;;
    8)
        check_logs
        ;;
    9)
        display_current_settings
        ;;
    10)
        remove_node
        ;;
    11)
        echo -e "\n${GREEN}👋 Goodbye!${NC}\n"
        exit 0
        ;;
    *)
        error_message "Invalid choice! Please enter a number from 1 to 11."
        ;;
esac
    
    echo -e "\nPress Enter to return to menu..."
    read
done

