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
    
    # Extract current RPC endpoints if env file exists
    if [ -f ~/t3rn/executor.env ]; then
        current_rpc=$(grep "RPC_ENDPOINTS" ~/t3rn/executor.env | sed "s/RPC_ENDPOINTS='//" | sed "s/'$//")
        if [ -n "$current_rpc" ]; then
            RPC_ENDPOINTS="$current_rpc"
        fi
    fi
    
    # For each network, ask for custom RPC
    for network in "${!networks[@]}"; do
        code=${networks[$network]}
        echo -e "${YELLOW}🔌 Enter additional RPC endpoint for ${network} (press Enter to skip):${NC}"
        read -p "➜ " new_rpc
        
        if [ -n "$new_rpc" ]; then
            # Add the new RPC to the array if it doesn't already exist
            if [[ ! "$RPC_ENDPOINTS" =~ "$new_rpc" ]]; then
                RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS" | jq ".$code += [\"$new_rpc\"]")
                success_message "Added RPC endpoint for ${network}"
            else
                info_message "This RPC endpoint is already in the list"
            fi
        else
            info_message "Using default RPC endpoints for ${network}"
        fi
    done
}# Function for checking logs
check_logs() {
    echo -e "\n${BOLD}${BLUE}📊 Checking T3rn Executor Node logs...${NC}\n"
    sudo journalctl -u t3rn-executor -f --no-hostname
}#!/bin/bash

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

# Check for curl and install if not present
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Clear screen
clear

# Function variables that will be set during installation
PRIVATE_KEY_LOCAL=""

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
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}📊  Check Logs${NC}"
    echo -e "${WHITE}[${CYAN}8${WHITE}] ${GREEN}➜ ${WHITE}♻️  Remove Node${NC}"
    echo -e "${WHITE}[${CYAN}9${WHITE}] ${GREEN}➜ ${WHITE}🚶  Exit${NC}\n"
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
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}⬅️  Back to Main Menu${NC}\n"
}

# Function for installing the node
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Installing T3rn Executor Node...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/6${WHITE}] ${GREEN}➜ ${WHITE}⚒️ Installing dependencies...${NC}"
    install_dependencies

    echo -e "${WHITE}[${CYAN}2/6${WHITE}] ${GREEN}➜ ${WHITE}📥 Downloading and setting up the node...${NC}"
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
    EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API="true"
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
    
    echo -e "${WHITE}[${CYAN}3/6${WHITE}] ${GREEN}➜ ${WHITE}🔑 Setting up private key...${NC}"
    set_private_key
    
    setup_rpc_endpoints
    
    echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}⛽ Setting up gas settings...${NC}"
    set_gas_settings
    
    # Create the environment file
    echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Creating environment file...${NC}"
    cat > ~/t3rn/executor.env << EOF
ENVIRONMENT=${ENVIRONMENT}
LOG_LEVEL=${LOG_LEVEL}
LOG_PRETTY=${LOG_PRETTY}
EXECUTOR_PROCESS_BIDS_ENABLED=${EXECUTOR_PROCESS_BIDS_ENABLED}
EXECUTOR_PROCESS_ORDERS_ENABLED=${EXECUTOR_PROCESS_ORDERS_ENABLED}
EXECUTOR_PROCESS_CLAIMS_ENABLED=${EXECUTOR_PROCESS_CLAIMS_ENABLED}
PRIVATE_KEY_LOCAL=${PRIVATE_KEY_LOCAL}
ENABLED_NETWORKS=${ENABLED_NETWORKS}
RPC_ENDPOINTS='${RPC_ENDPOINTS}'
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
PROMETHEUS_PORT=9091
EOF
    success_message "Environment file created at ~/t3rn/executor.env"
    
    # Create systemd service
    echo -e "${WHITE}[${CYAN}6/6${WHITE}] ${GREEN}➜ ${WHITE}▶️ Creating and starting systemd service...${NC}"
    
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

    echo -e "${WHITE}[${CYAN}1/4${WHITE}] ${GREEN}➜ ${WHITE}⚒️ Installing dependencies...${NC}"
    install_dependencies

    echo -e "${WHITE}[${CYAN}2/4${WHITE}] ${GREEN}➜ ${WHITE}♻️ Removing old files...${NC}"
    # Backup the environment file
    if [ -f ~/t3rn/executor.env ]; then
        cp ~/t3rn/executor.env ~/t3rn/executor.env.backup
        success_message "Environment file backed up"
    fi
    
    # Remove old files
    rm -rf ~/t3rn/executor
    rm -rf ~/t3rn/executor-linux-*.tar.gz
    success_message "Old files removed"

    echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}📥 Downloading and setting up the node...${NC}"
    cd ~/t3rn
    
    # Define current user name and home directory
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)
    
    # Set environment variables if not backed up
    if [ ! -f ~/t3rn/executor.env.backup ]; then
        ENVIRONMENT="testnet"
        LOG_LEVEL="debug"
        LOG_PRETTY="false"
        EXECUTOR_PROCESS_BIDS_ENABLED="true"
        EXECUTOR_PROCESS_ORDERS_ENABLED="true"
        EXECUTOR_PROCESS_CLAIMS_ENABLED="true"
        ENABLED_NETWORKS="blast-sepolia,unichain-sepolia,arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn"
        
        # Default RPC endpoints
        RPC_ENDPOINTS='{
            "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
            "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
            "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
            "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
            "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"],
            "blst": ["https://sepolia.blast.io", "https://endpoints.omniatech.io/v1/blast/sepolia/public"]
        }'
    fi
    
    # Download latest release
    info_message "Downloading the latest T3rn executor release..."
    LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    wget -q https://github.com/t3rn/executor-release/releases/download/${LATEST_TAG}/executor-linux-${LATEST_TAG}.tar.gz
    
    # Extract the archive
    info_message "Extracting files..."
    tar -xzf executor-linux-*.tar.gz
    
    echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}🔑 Setting up private key...${NC}"
    set_private_key
    
    setup_rpc_endpoints
    
    echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}⛽ Setting up gas settings...${NC}"
    set_gas_settings

    echo -e "${WHITE}[${CYAN}4/4${WHITE}] ${GREEN}➜ ${WHITE}▶️ Creating and starting systemd service...${NC}"
    
    # Define current user name and home directory
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)
    
    # Create service file
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
    echo -e "${GREEN}✓ T3rn Executor Node successfully updated and started!${NC}"
    echo -e "${YELLOW}ℹ️ To check node logs, run:${NC} ${CYAN}sudo journalctl -u t3rn-executor -f --no-hostname${NC}"
    if grep -q "PROMETHEUS_PORT=9091" ~/t3rn/executor.env; then
        echo -e "${YELLOW}ℹ️ Node is using port 9091 for Prometheus metrics${NC}"
    else
        echo -e "${YELLOW}ℹ️ Node is using default Prometheus port. If you have port conflicts, run option 3 to change it.${NC}"
    fi
    echo -e "${PURPLE}═════════════════════════════════════════════════════════════════════${NC}\n"
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
    if [ -f ~/t3rn/executor.env ]; then
        current_rpc=$(grep "RPC_ENDPOINTS" ~/t3rn/executor.env | sed "s/RPC_ENDPOINTS='//" | sed "s/'$//")
    else
        current_rpc="$RPC_ENDPOINTS"
    fi
    
    # Get new RPC endpoint from user
    echo -e "${YELLOW}🔢 Enter new RPC endpoint for ${network_name}:${NC}"
    read -p "➜ " new_rpc
    
    # Validate input
    if [ -z "$new_rpc" ]; then
        error_message "RPC endpoint cannot be empty"
        return
    fi
    
    # Update RPC in JSON structure
    # First, extract the array for the network
    local network_array=$(echo "$current_rpc" | jq -r ".\"$network_code\"")
    
    # Add the new RPC to the array if it doesn't already exist
    if [[ ! "$network_array" =~ "$new_rpc" ]]; then
        updated_rpc=$(echo "$current_rpc" | jq ".$network_code += [\"$new_rpc\"]")
        
        # Update the environment file
        if [ -f ~/t3rn/executor.env ]; then
            sed -i "s|RPC_ENDPOINTS='.*'|RPC_ENDPOINTS='$updated_rpc'|" ~/t3rn/executor.env
            success_message "RPC endpoint for ${network_name} updated"
        else
            RPC_ENDPOINTS="$updated_rpc"
            warning_message "No environment file found. Settings will be applied on next install."
        fi
    else
        warning_message "This RPC endpoint is already in the list"
    fi
}

# Function for setting up private key
set_private_key() {
    echo -e "${YELLOW}🔑 Enter your private key (with or without '0x' prefix):${NC}"
    read -s -p "➜ " private_key
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
    success_message "Private key set"
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
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
EOF
        success_message "Gas settings created"
    fi
}

# Function for modifying existing gas settings
change_gas_settings() {
    set_gas_settings
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
    echo -e "${BOLD}${BLUE}📝 Enter action number [1-8]:${NC} "
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
                echo -e "${BOLD}${BLUE}📝 Enter selection [1-6]:${NC} "
                read -p "➜ " rpc_choice
                
                if [ "$rpc_choice" -eq 6 ]; then
                    break
                elif [ "$rpc_choice" -ge 1 ] && [ "$rpc_choice" -le 5 ]; then
                    change_rpc "$rpc_choice"
                    echo -e "\nPress Enter to return to RPC menu..."
                    read
                else
                    error_message "Invalid choice! Please enter a number from 1 to 6."
                    echo -e "\nPress Enter to continue..."
                    read
                fi
            done
            ;;
        5)
            change_gas_settings
            ;;
        6)
            set_private_key
            ;;
        7)
            check_logs
            ;;
        8)
            remove_node
            ;;
        9)
            echo -e "\n${GREEN}👋 Goodbye!${NC}\n"
            exit 0
            ;;
        *)
            error_message "Invalid choice! Please enter a number from 1 to 9."
            ;;
    esac
    
    echo -e "\nPress Enter to return to menu..."
    read
done
