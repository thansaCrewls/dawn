#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/Dawn.sh"
DAWN_DIR="$HOME/Dawn"

# Check if the script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root privileges."
    echo "Please try to switch to the root user using the 'sudo -i' command and then run this script again."
    exit 1
fi

# Install and configure functions
function install_and_configure() {
    # Check if Python 3.11 is installed
    function check_python_installed() {
        if command -v python3.11 &>/dev/null; then
            echo "Python 3.11 is installed."
        else
            echo "Python 3.11 is not installed. Installing..."
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
        python3.11 -m pip install --upgrade pip # Upgrade pip
        echo "Python 3.11 and pip installed."
    }

    # Check Python version
    check_python_installed

    # Update the package list and install git and tmux
    echo "Updating package lists and installing git and tmux..."
    sudo apt update
    sudo apt install -y git tmux python3.11-venv libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev

    # Check if the Dawn directory exists and delete it if it exists	
    if [ -d "$DAWN_DIR" ]; then	
        echo "Detected that Dawn directory already exists, deleting..."	
        rm -rf "$DAWN_DIR"	
        echo "Dawn directory deleted."	
    fi
    
    # Clone the GitHub repository
    echo "Cloning repository from GitHub..."
    git clone https://github.com/sdohuajia/Dawn-py.git "$DAWN_DIR"

    # Check if the cloning operation was successful
    if [ ! -d "$DAWN_DIR" ]; then
        echo "Cloning failed, please check the network connection or repository address."
        exit 1
    fi

    # Enter the warehouse directory
    cd "$DAWN_DIR" || { echo "Unable to enter Dawn directory"; exit 1; }

    # Create and activate a virtual environment
    echo "Creating and activating virtual environment..."
    python3.11 -m venv venv
    source "$DAWN_DIR/venv/bin/activate"

    # Install dependencies
    echo "Installing required Python packages..."
    if [ ! -f requirements.txt ]; then
        echo "requirements.txt file not found, unable to install dependencies."
        exit 1
    fi
    pip install -r requirements.txt
    pip install httpx

    # Configure email and password
    read -p "Please enter your email address and password in the format email:password: " email_password
    farm_file="$DAWN_DIR/config/data/farm.txt"

    # Write the email address and password to the file
    echo "$email_password" > "$farm_file"
    echo "Email and password have been added to $farm_file."

    # Configure proxy information
    read -p "Please enter your proxy information in the format (http://user:pass@ip:port): " proxy_info
    proxies_file="$DAWN_DIR/config/data/proxies.txt"

    # Write proxy information to a file
    echo "$proxy_info" > "$proxies_file"
    echo "Proxy information has been added to $proxies_file."

    echo "Installation, cloning, virtual environment setup and configuration completed!"
    echo "Running script python3.11 run.py..."
    
    # Create a new session using tmux and run the Python script in it
    tmux new-session -d -s dawn # Create a new tmux session
    tmux send-keys -t dawn "cd $DAWN_DIR" Cm # Switch to the Dawn directory
    tmux send-keys -t dawn "source \"$DAWN_DIR/venv/bin/activate\"" Cm # Activate virtual environment
    tmux send-keys -t dawn "python3.11 run.py" Cm # Run Python script
    tmux attach-session -t dawn # connect to the session

    echo "Use 'tmux attach -t dawn' command to view the log."
    echo "To exit the tmux session, press Ctrl+B then D."

    # Prompt the user to press any key to return to the main menu
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Install and configure Grassnode function
function setup_grassnode() {
    # Check if the grass directory exists, and delete it if it exists
    if [ -d "grass" ]; then
        echo "The grass directory is detected to exist, deleting..."
        rm -rf grass
        echo "grass directory has been deleted."
    fi

    # Check and terminate existing grass tmux sessions
    if tmux has-session -t grass 2>/dev/null; then
        echo "A running grass session has been detected, terminating..."
        tmux kill-session -t grass
        echo "Terminated existing Nodepay session."
    fi
    
    # Install npm environment
    sudo apt update
    sudo apt install -y nodejs npm
    sudo apt-get install tmux
    sudo apt install node-cacache node-gyp node-mkdirp node-nopt node-tar node-which

    # Check Node.js version
    node_version=$(node ​​-v 2>/dev/null)
    if [[ $? -ne 0 || "$node_version" != v16* ]]; then
        echo "The current Node.js version is $node_version, installing Node.js 16..."
        # Install Node.js 16
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt install -y nodejs
    else
        echo "Node.js version meets the requirements: $node_version"
    fi

    echo "Cloning grass repository from GitHub..."
    git clone https://github.com/sdohuajia/grass-2.0.git grass
    if [ ! -d "grass" ]; then
        echo "Cloning failed, please check the network connection or repository address."
        exit 1
    fi

    cd "grass" || { echo "Unable to enter grass directory"; exit 1; }

    # Configure proxy information
    read -p "Please enter your proxy information in the format of http://user:pass@ip:port: " proxy_info
    proxy_file="/root/grass/proxy.txt" # Update the file path to /root/grass/proxy.txt

    # Write proxy information to a file
    echo "$proxy_info" > "$proxy_file"
    echo "Proxy information has been added to $proxy_file."

    # Get the user ID and write it to uid.txt
    read -p "Please enter your userId: " user_id
    uid_file="/root/grass/uid.txt" # uid file path

    # Write userId to the file
    echo "$user_id" > "$uid_file"
    echo "userId has been added to $uid_file."

    # Install npm dependencies
    echo "Installing npm dependencies..."
    npm install

    # Use tmux to automatically run npm start
    tmux new-session -d -s grass # Create a new tmux session named grass
    tmux send-keys -t teneo "cd grass" Cm # Switch to the grass directory
    tmux send-keys -t grass "npm start" Cm # Start npm start
    echo "npm started in tmux session."
    echo "Use 'tmux attach -t grass' command to view the log."
    echo "To exit the tmux session, press Ctrl+B then D."

    # Prompt the user to press any key to return to the main menu
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Install and configure Teneo functions
function setup_Teneonode() {
    # Check if the teneo directory exists, delete it if it exists
    if [ -d "teneo" ]; then
        echo "The teneo directory has been detected and is being deleted..."
        rm -rf teneo
        echo "The teneo directory has been deleted."
    fi
    
    # Install Python 3.11
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt-get install -y python3-apt
    # Add python3.11-venv installation
    sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
    echo "Python 3.11 and pip installed."

    echo "Cloning teneo repository from GitHub..."
    git clone https://github.com/sdohuajia/Teneo.git teneo
    if [ ! -d "teneo" ]; then
        echo "Cloning failed, please check the network connection or repository address."
        exit 1
    fi

    cd "teneo" || { echo "Unable to enter teneo directory"; exit 1; }

    # Create a virtual environment
    python3.11 -m venv venv # Create a virtual environment
    source venv/bin/activate # Activate the virtual environment
    
    echo "Installing required Python packages..."
    if [ ! -f requirements.txt ]; then
        echo "requirements.txt file not found, unable to install dependencies."
        exit 1
    fi
    
    python3.11 -m pip install -r requirements.txt

    # Manually install httpx
    python3.11 -m pip install httpx

    # Configure proxy information
    read -p "Please enter your proxy information in the format of http://user:pass@ip:port: " proxy_info
    proxies_file="/root/teneo/proxies.txt"

    # Write proxy information to a file
    echo "$proxy_info" > "$proxies_file"
    echo "Proxy information has been added to $proxies_file."

    # Run setup.py
    [ -f setup.py ] && { echo "Running setup.py..."; python3.11 setup.py; }

    echo "Starting main.py using tmux..."
    tmux new-session -d -s teneo # Create a new tmux session named teneo
    tmux send-keys -t teneo "cd teneo" Cm # Switch to the teneo directory
    tmux send-keys -t teneo "source \"venv/bin/activate\"" Cm # Activate the virtual environment
    tmux send-keys -t teneo "python3 main.py" Cm # Start main.py
    echo "Use 'tmux attach -t teneo' command to view the log."
    echo "To exit the tmux session, press Ctrl+B then D."

    # Prompt the user to press any key to return to the main menu
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Install and configure Humanity functions
function setup_Humanity() {
    # Check if the Humanity directory exists, and delete it if it exists
    if [ -d "Humanity" ]; then
        echo "The Humanity directory has been detected and is being deleted..."
        rm -rf Humanity
        echo "Humanity directory deleted."
    fi
    
    # Install Python 3.11
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt-get install -y python3-apt
    # Add python3.11-venv installation
    sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
    echo "Python 3.11 and pip installed."

    echo "Cloning teneo repository from GitHub..."
    git clone https://github.com/sdohuajia/Humanity.git
    if [ ! -d "Humanity" ]; then
        echo "Cloning failed, please check the network connection or repository address."
        exit 1
    fi

    cd "Humanity" || { echo "Unable to enter Humanity directory"; exit 1; }

    # Create a virtual environment
    python3.11 -m venv venv # Create a virtual environment
    source venv/bin/activate # Activate the virtual environment
    
    echo "Installing required Python packages..."
    if [ ! -f requirements.txt ]; then
        echo "requirements.txt file not found, unable to install dependencies."
        exit 1
    fi
    
    python3.11 -m pip install -r requirements.txt

    # Manually install httpx
    python3.11 -m pip install httpx

    # Configure private key information
    read -p "Please enter your private key: " private_key
    private_keys_file="/root/Humanity/private_keys.txt"

    # Write the private key information to the file
    echo "$private_key" >> "$private_keys_file"
    echo "Private key information has been added to $private_keys_file."

    # Run the script
    echo "Starting bot.py using tmux..."
    tmux new-session -d -s Humanity # Create a new tmux session named Humanity
    tmux send-keys -t Humanity "cd Humanity" Cm # Switch to the teneo directory
    tmux send-keys -t Humanity "source \"venv/bin/activate\"" Cm # Activate virtual environment
    tmux send-keys -t Humanity "python3 bot.py" Cm # Start bot.py
    echo "Use 'tmux attach -t Humanity' command to view the log."
    echo "To exit the tmux session, press Ctrl+B then D."

    # Prompt the user to press any key to return to the main menu
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Install and configure Nodepay functions
function setup_Nodepay() {
    # Check if the Nodepay directory exists, delete it if it exists
    if [ -d "Nodepay" ]; then
        echo "Nodepay directory is detected to exist, deleting..."
        rm -rf Nodepay
        echo "Nodepay directory has been deleted."
    fi
    
    # Check and terminate existing Nodepay tmux sessions
    if tmux has-session -t Nodepay 2>/dev/null; then
        echo "A running Nodepay session has been detected, terminating..."
        tmux kill-session -t Nodepay
        echo "Terminated existing Nodepay session."
    fi
    
    # Install Python 3.11
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt-get install -y python3-apt
    # Add python3.11-venv installation
    sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
    echo "Python 3.11 and pip installed."

    echo "Cloning Nodepay repository from GitHub..."
    git clone https://github.com/sdohuajia/Nodepay.git Nodepay
    if [ ! -d "Nodepay" ]; then
        echo "Cloning failed, please check the network connection or repository address."
        exit 1
    fi

    cd "Nodepay" || { echo "Unable to enter Nodepay directory"; exit 1; }

    echo "Installing required Python packages..."
    if [ ! -f requirements.txt ]; then
        echo "requirements.txt file not found, unable to install dependencies."
        exit 1
    fi
    
    python3.11 -m pip install -r requirements.txt

    # Manually install httpx
    python3.11 -m pip install httpx

    # Configure proxy information
    read -p "Please enter your proxy information, the format is http://user:pass@ip:port or socks5://user:pass@ip:port: " proxy_info
    proxies_file="/root/Nodepay/proxy.txtt"

    # Write proxy information to a file
    echo "$proxy_info" > "$proxies_file"
    echo "Proxy information has been added to $proxies_file."

    # Get the user ID and write it to uid.txt
    read -p "Please enter your np_tokens: " user_id
    uid_file="/root/Nodepay/np_tokens.txt" # uid file path

    # Write userId to the file
    echo "$user_id" > "$uid_file"
    echo "userId has been added to $uid_file."

    echo "Starting main.py using tmux..."
    tmux new-session -d -s Nodepay
    tmux send-keys -t Nodepay "cd Nodepay" Cm
    tmux send-keys -t Nodepay "python3 main.py" Cm
    echo "Use 'tmux attach -t Nodepay' command to view the log."
    echo "To exit the tmux session, press Ctrl+B then D."

    # Prompt the user to press any key to return to the main menu
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "The script was written by the big gambling community hahahaha, Twitter @ferdie_jhovie, free and open source, please don't believe in the charges"
        echo "If you have any questions, please contact Twitter. There is only one number for this."
        echo "================================================ ================"
        echo "To exit the script, press ctrl + C on your keyboard to exit"
        echo "Please select the action to perform:"
        echo "1. Install and deploy Dawn"
        echo "2. Install and deploy Grass"
        echo "3. Install and deploy Teneo"
        echo "4. Humanity Daily Sign-in"
        echo "5. Install and deploy Nodepay"
        echo "6. Exit"

        read -p "Please enter your choice (1,2,3,4,5,6): " choice
        case $choice in
            1)
                install_and_configure # Call installation and configuration functions
                ;;
            2)
                setup_grassnode #Call installation and configuration functions
                ;;
            3)
                setup_Teneonode #Call installation and configuration functions
                ;;    
            4)
                setup_Humanity #Call installation and configuration functions
                ;;    
            5)
                setup_Nodepay #Call installation and configuration functions
                ;;    
            6)
                echo "Exit script..."
                exit 0
                ;;
            *)
                echo "Invalid selection, please try again."
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
        esac
    done
}

# Enter the main menu
main_menu
