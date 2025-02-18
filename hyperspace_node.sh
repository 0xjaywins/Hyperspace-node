#!/bin/bash
# Hyperspace Node Setup Script (Secure and Simple)
# Brought to you by 0xjay_wins 🚀
# ----------------------------
# Welcome Message
# ----------------------------
echo "=============================================="
echo "Welcome to the Hyperspace Node Setup Script!"
echo "Curated with ❤️ by 0xjay_wins"
echo "Follow me on X: https://x.com/0xjay_wins"
echo "=============================================="
echo ""

# ----------------------------
# Install dependencies
# ----------------------------
echo "Checking for required dependencies..."
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    sudo apt-get update && sudo apt-get install -y screen
fi

# Cleanup
echo "Cleaning up previous installations..."
pkill -f "aios-cli" || true
screen -XS hyperspace quit || true
rm -rf ~/.hyperspace ~/.cache/hyperspace
[ -f ~/.config/key.pem ] && cp ~/.config/key.pem ~/hyperspace_key_old.pem && rm ~/.config/key.pem

# Ensure the correct PATH is loaded
echo "Loading environment variables..."
source /root/.bashrc  # Source the shell configuration file to load the updated PATH

# Install + Setup
echo "Installing Hyperspace..."
curl -s https://download.hyper.space/api/install | bash

echo "Creating screen session..."
screen -S hyperspace -dm

# Function to handle "Another instance is already running" scenario
handle_instance_conflict() {
    echo "Checking for 'Another instance is already running'..."
    screen -S hyperspace -X hardcopy /tmp/hyperspace_log
    if grep -q "Another instance is already running" /tmp/hyperspace_log; then
        echo "Another instance is already running. Killing existing instance..."
        aios-cli kill
        sleep 2 # Wait for the process to be killed
        echo "Instance killed. Retrying command..."
        return 0
    else
        echo "No instance conflict detected."
        return 1
    fi
}

# Start daemon within the screen session
echo "Starting daemon..."
screen -S hyperspace -X stuff "aios-cli start
"
sleep 2 # Give some time for the command to execute

# Handle instance conflict for daemon start
if handle_instance_conflict; then
    echo "Retrying daemon start..."
    screen -S hyperspace -X stuff "aios-cli start
    "
    sleep 10 # Wait for the daemon to start
fi

# Wait for daemon to start with a timeout mechanism
timeout=20
while [ $timeout -gt 0 ]; do
    if screen -list | grep -q "hyperspace"; then
        echo "Daemon started successfully. Proceeding..."
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

# Detach screen to allow smooth execution of the next steps
screen -d -S hyperspace

# Function to install Mistral-7B model with retries
install_model_with_retries() {
    local retries=3
    local attempt=1

    while [ $attempt -le $retries ]; do
        echo "Attempt $attempt to install Mistral-7B model..."
        if aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf; then
            echo "Mistral-7B model installed successfully."
            return 0
        else
            echo "Model installation failed. Retrying in 10 seconds..."
            sleep 10
            attempt=$((attempt + 1))
        fi
    done

    echo "Failed to install Mistral-7B model after $retries attempts. Continuing with the setup..."
    return 1
}

# Install Mistral-7B model with retries
install_model_with_retries

# Ensure the daemon has time to initialize before connecting
echo "Waiting 10 seconds before connecting to model..."
sleep 40

# Connect to model
echo "Connecting to model..."
screen -S hyperspace -X stuff "
aios-cli start --connect
"
sleep 2 # Give some time for the command to execute

# Handle instance conflict for model connection
if handle_instance_conflict; then
    echo "Retrying connection to model..."
    screen -S hyperspace -X stuff "aios-cli start --connect
    "
    sleep 20
else
    echo "Connection to model successful."
    sleep 20
fi

# Allocate Hive RAM
echo "Allocating Hive RAM..."
aios-cli hive allocate 9

# Save private key
echo "Saving private key..."
[ -f ~/.config/key.pem ] && cp ~/.config/key.pem ~/hyperspace_key.pem

echo "Setup complete! Key saved to ~/hyperspace_key.pem"
aios-cli hive points

# ----------------------------
# Completion Message
# ----------------------------
echo "=============================================="
echo "Setup complete! 🎉"
echo "Your private key is securely stored at ~/.hyperspace/secure/key.pem."
echo "To access your key, use:"
echo "  cat ~/.hyperspace/secure/key.pem"
echo ""
echo "Thank you for using the Hyperspace Node Setup Script by 0xjay_wins!"
echo "Follow me on X for updates: https://x.com/0xjay_wins"
echo "=============================================="
