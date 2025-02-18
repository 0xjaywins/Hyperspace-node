#!/bin/bash

# Hyperspace Node Setup Script (Clean Install + Auto-Setup)

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

# Start daemon within the screen session
echo "Starting daemon..."
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

# Check if "Another instance is already running" is in the screen log
if screen -S hyperspace -X hardcopy /tmp/hyperspace_log && grep -q "Another instance is already running" /tmp/hyperspace_log; then
    echo "Another instance is already running. Killing existing instance..."
    aios-cli kill
    sleep 2 # Wait for the process to be killed
    echo "Retrying daemon start..."
    screen -S hyperspace -X stuff "aios-cli start
    "
    sleep 10 # Wait for the daemon to start again
else
    echo "Daemon started successfully."
fi

# Detach screen to allow smooth execution of the next steps
screen -d -S hyperspace

# Install Mistral-7B model
echo "Installing Mistral-7B model..."
aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf

# Ensure the daemon has time to initialize before connecting
echo "Waiting 10 seconds before connecting to model..."
sleep 40

# Connect to model with error handling for "Another instance is already running"
echo "Connecting to model..."
screen -S hyperspace -X stuff "
aios-cli start --connect
"
sleep 2 # Give some time for the command to execute

# Check if "Another instance is already running" is in the screen log
if screen -S hyperspace -X hardcopy /tmp/hyperspace_log && grep -q "Another instance is already running" /tmp/hyperspace_log; then
    echo "Another instance is already running. Killing existing instance..."
    aios-cli kill
    sleep 2 # Wait for the process to be killed
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
