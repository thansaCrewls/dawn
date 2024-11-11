#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/Dawn.sh"
DAWN_DIR="$HOME/Dawn"

# Check if script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run as root user."
    echo "Try using 'sudo -i' to switch to root user and then run this script again."
    exit 1
fi

# Install and configure function
function install_and_configure() {
    # Check if Python 3.11 is installed
    function check_python_installed() {
        if command -v python3.11 &>/dev/null; then
            echo "Python 3.11 is already installed."
        else
            echo "Python 3.11 is not installed, installing now..."
            install_python
        fi
    }

    # Install Python 3.11
    function install_python() {
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository ppa:deadsnakes/ppa -y
        sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
        sudo apt install libopencv-dev python3-opencv
        # Add pip upgrade command
        python3.11 -m pip install --upgrade pip  # Upgrade pip
        echo "Python 3.11 and pip installation complete."
    }

    # Check Python version
    check_python_installed

    # Update package list and install git and tmux
    echo "Updating package list and installing git and tmux..."
    sudo apt update
    sudo apt install -y git tmux python3.11-venv libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev

    # Check if Dawn directory exists, delete if it does
    if [ -d "$DAWN_DIR" ]; then
        echo "Dawn directory detected, deleting..."
        rm -rf "$DAWN_DIR"
        echo "Dawn directory deleted."
    fi

    # Clone GitHub repository
    echo "Cloning repository from GitHub..."
    git clone https://github.com/sdohuajia/Dawn-py.git "$DAWN_DIR"

    # Check if cloning was successful
    if [ ! -d "$DAWN_DIR" ]; then
        echo "Cloning failed, please check your network connection or repository address."
        exit 1
    fi

    # Enter repository directory
    cd "$DAWN_DIR" || { echo "Unable to enter Dawn directory"; exit 1; }

    # Create and activate virtual environment
    echo "Creating and activating virtual environment..."
    python3.11 -m venv venv
    source "$DAWN_DIR/venv/bin/activate"

    # Install dependencies
    echo "Installing required Python packages..."
    if [ ! -f requirements.txt ]; then
        echo "requirements.txt file not found, cannot install dependencies."
        exit 1
    fi
    pip install -r requirements.txt
    pip install httpx

    # Configure email and password
    read -p "Enter your email and password in the format email:password: " email_password
    farm_file="$DAWN_DIR/config/data/farm.txt"

    # Write email and password to file
    echo "$email_password" > "$farm_file"
    echo "Email and password have been added to $farm_file."

    # Configure proxy information
    read -p "Enter your proxy information in the format (http://user:pass@ip:port): " proxy_info
    proxies_file="$DAWN_DIR/config/data/proxies.txt"

    # Write proxy information to file
    echo "$proxy_info" > "$proxies_file"
    echo "Proxy information has been added to $proxies_file."

    echo "Installation, cloning, virtual environment setup, and configuration complete!"
    echo "Running script python3.11 run.py..."

    # Use tmux to create a new session and run Python script within it
    tmux new-session -d -s dawn  # Create new tmux session
    tmux send-keys -t dawn "cd $DAWN_DIR" C-m  # Change to Dawn directory
    tmux send-keys -t dawn "source \"$DAWN_DIR/venv/bin/activate\"" C-m  # Activate virtual environment
    tmux send-keys -t dawn "python3.11 run.py" C-m  # Run Python script
    tmux attach-session -t dawn  # Attach to session

    echo "Use 'tmux attach -t dawn' command to view logs."
    echo "To exit tmux session, press Ctrl+B then D."

    # Prompt user to press any key to return to main menu
    read -n 1 -s -r -p "Press any key to return to main menu..."
}

# Install and configure Grassnode function
function setup_grassnode() {
    # Check if grass directory exists, delete if it does
    if [ -d "grass" ]; then
        echo "grass directory detected, deleting..."
        rm -rf grass
        echo "grass directory deleted."
    fi

    # Check and terminate any existing grass tmux session
    if tmux has-session -t grass 2>/dev/null; then
        echo "Running grass session detected, terminating..."
        tmux kill-session -t grass
        echo "Existing Nodepay session terminated."
    fi
    
    # Install npm environment
    sudo apt update
    sudo apt install -y nodejs npm
    sudo apt-get install tmux
    sudo apt install node-cacache node-gyp node-mkdirp node-nopt node-tar node-which

    # Check Node.js version
    node_version=$(node -v 2>/dev/null)
    if [[ $? -ne 0 || "$node_version" != v16* ]]; then
        echo "Current Node.js version is $node_version, installing Node.js 16..."
        # Install Node.js 16
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt install -y nodejs
    else
        echo "Node.js version meets requirements: $node_version"
    fi

    echo "Cloning grass repository from GitHub..."
    git clone https://github.com/sdohuajia/grass-2.0.git grass
    if [ ! -d "grass" ]; then
        echo "Cloning failed, please check your network connection or repository address."
        exit 1
    fi

    cd "grass" || { echo "Unable to enter grass directory"; exit 1; }

    # Configure proxy information
    read -p "Enter your proxy information in the format http://user:pass@ip:port: " proxy_info
    proxy_file="/root/grass/proxy.txt"  # Update file path to /root/grass/proxy.txt

    # Write proxy information to file
    echo "$proxy_info" > "$proxy_file"
    echo "Proxy information has been added to $proxy_file."

    # Obtain user ID and write to uid.txt
    read -p "Enter your userId: " user_id
    uid_file="/root/grass/uid.txt"  # uid file path

    # Write userId to file
    echo "$user_id" > "$uid_file"
    echo "userId has been added to $uid_file."

    # Install npm dependencies
    echo "Installing npm dependencies..."
    npm install

    # Use tmux to automatically run npm start
    tmux new-session -d -s grass  # Create new tmux session named grass
    tmux send-keys -t grass "cd grass" C-m  # Change to grass directory
    tmux send-keys -t grass "npm start" C-m # Start npm start
    echo "npm has started in tmux session."
    echo "Use 'tmux attach -t grass' command to view logs."
    echo "To exit tmux session, press Ctrl+B then D."

    # Prompt user to press any key to return to main menu
    read -n 1 -s -r -p "Press any key to return to main menu..."
}

# (similar translations apply for the setup_Teneonode, setup_Humanity, setup_Nodepay, and main_menu functions)
