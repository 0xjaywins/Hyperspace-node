#!/bin/bash
# Hyperspace Node Setup Script (Clean Install + Auto-Setup)

# ----------------------------
# Source .bashrc
# ----------------------------
echo "Sourcing /root/.bashrc to load environment variables..."
source /root/.bashrc

# ----------------------------
# Install Dependencies
# ----------------------------
echo "Installing dependencies..."

# Install curl and screen
if ! command -v curl &> /dev/null || ! command -v screen &> /dev/null; then
  echo "Installing curl and screen..."
  sudo apt update
  sudo apt install -y curl screen
fi

# Install Node.js and npm using nvm
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
  echo "Installing Node.js and npm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
fi

# Cleanup
echo "Cleaning up previous installations..."
pkill -f "aios-cli" || true
screen -XS hyperspace quit || true
rm -rf ~/.hyperspace ~/.cache/hyperspace
[ -f ~/.config/key.pem ] && cp ~/.config/key.pem ~/hyperspace_key_old.pem && rm ~/.config/key.pem

# Install + Setup
echo "Installing Hyperspace..."
curl -s https://download.hyper.space/api/install | bash

echo "Creating screen session..."
screen -S hyperspace -dm

# Function to check and kill existing instances
check_and_kill_instance() {
    if aios-cli status 2>&1 | grep -q "Another instance is already running"; then
        echo "Detected running instance. Killing it..."
        aios-cli kill
        sleep 5  # Wait for process to fully terminate
        return 0
    fi
    return 1
}
# Start daemon within the screen session
echo "Starting daemon..."
check_and_kill_instance  # Check before starting
screen -S hyperspace -X stuff "aios-cli start
"

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

# Install Mistral-7B model
echo "Installing Mistral-7B model..."
# Check for running instance before model installation
check_and_kill_instance
aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf

# Ensure the daemon has time to initialize before connecting
echo "Waiting 40 seconds before connecting to model..."
sleep 40

echo "Connecting to model..."
# Check for running instance before connecting
check_and_kill_instance
screen -S hyperspace -X stuff "
aios-cli start --connect
"

sleep 20

echo "Allocating Hive RAM..."
# Check for running instance before allocation
check_and_kill_instance
aios-cli hive allocate 9

# Save private key
echo "Saving private key..."
[ -f ~/.config/key.pem ] && cp ~/.config/key.pem ~/hyperspace_key.pem

echo "Setup complete! Key saved to ~/hyperspace_key.pem"

# Final check and display points
check_and_kill_instance
aios-cli hive points
