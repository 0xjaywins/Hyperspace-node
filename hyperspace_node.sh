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

# ----------------------------
# Cleanup
# ----------------------------
echo "Cleaning up previous installations..."
pkill -f "aios-cli" || true
screen -XS hyperspace quit 2>/dev/null || true
rm -rf ~/.hyperspace ~/.cache/hyperspace 2>/dev/null || true

# Function to find the key file
find_key_file() {
    # Common locations where the key might be
    key_locations=(
        "$HOME/.config/key.pem"
        "$HOME/.hyperspace/key.pem"
        "$HOME/.local/share/hyperspace/key.pem"
        "$HOME/.aios/key.pem"
    )
    
    for location in "${key_locations[@]}"; do
        if [ -f "$location" ]; then
            echo "$location"
            return 0
        fi
    done
    return 1
}

# Backup old key securely
if old_key=$(find_key_file); then
    echo "Backing up old key securely..."
    mkdir -p ~/.hyperspace/secure
    chmod 700 ~/.hyperspace/secure
    cp "$old_key" ~/.hyperspace/secure/key_old.pem
    chmod 600 ~/.hyperspace/secure/key_old.pem
    echo "Old key backed up to ~/.hyperspace/secure/key_old.pem"
    rm "$old_key"
fi

# ----------------------------
# Create a function to run commands in a properly sourced environment
# ----------------------------
run_with_bashrc() {
  bash --login -c "cd ~ && $*"
}

# ----------------------------
# Create a function to monitor and restart daemon if needed
# ----------------------------
restart_daemon_if_needed() {
  # Create a temporary file for output
  temp_output=$(mktemp)
  
  # Run the command and capture output
  screen -S hyperspace -X stuff "aios-cli status > $temp_output 2>&1^M"
  sleep 2
  
  # Check if "Another instance is already running" is in the output
  if grep -q "Another instance is already running" "$temp_output"; then
    echo "Detected 'Another instance is already running'. Killing and restarting daemon..."
    screen -S hyperspace -X stuff "aios-cli kill^M"
    sleep 3
    screen -S hyperspace -X stuff "aios-cli start^M"
    sleep 10
    return 0
  fi
  
  # Clean up
  rm -f "$temp_output"
  return 1
}

# ----------------------------
# Installation
# ----------------------------
echo "Installing Hyperspace..."
if ! curl -s https://download.hyper.space/api/install | bash; then
  echo "Failed to install Hyperspace. Please check your internet connection."
  exit 1
fi

# ----------------------------
# Verify Installation
# ----------------------------
echo "Verifying installation..."
if ! run_with_bashrc "command -v aios-cli"; then
  echo "Failed to find aios-cli. The installation may not have completed successfully."
  echo "Make sure to run 'source ~/.bashrc' or start a new terminal session."
  exit 1
fi

# ----------------------------
# Improved Screen Management for Daemon
# ----------------------------
echo "Starting daemon in a screen session..."

# Kill any existing sessions and processes
pkill -f "aios-cli" || true
screen -XS hyperspace quit 2>/dev/null || true

# Create a new screen session for the daemon
screen -dmS hyperspace bash -c "source ~/.bashrc && aios-cli start; exec bash"
echo "Daemon started in screen session 'hyperspace'"
sleep 10  # Give it time to initialize

# Check if we need to restart daemon
restart_daemon_if_needed

# Detach from screen to continue with model installation
echo "Installing Mistral-7B model..."
# Try multiple times in case of failure
MAX_ATTEMPTS=3
for i in $(seq 1 $MAX_ATTEMPTS); do
  if run_with_bashrc "aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf"; then
    echo "Model installed successfully on attempt $i."
    break
  else
    echo "Failed to install model on attempt $i of $MAX_ATTEMPTS."
    
    # Check if daemon needs restart
    if restart_daemon_if_needed; then
      echo "Daemon restarted due to 'Another instance is already running' error."
    fi
    
    if [ $i -eq $MAX_ATTEMPTS ]; then
      echo "Max attempts reached. Moving on..."
    else
      echo "Waiting before retrying..."
      sleep 10
    fi
  fi
done

# Now reattach to the screen session to connect to the model
echo "Connecting to model in screen session..."

# Send Ctrl+C to stop any running logs
screen -S hyperspace -X stuff $'\003'
sleep 2  # Give it time to stop the logs

# Send the connect command
screen -S hyperspace -X stuff "aios-cli connect^M"
sleep 5

# Function to ensure key is generated
ensure_key_generated() {
    echo "Checking for existing key..."
    if ! find_key_file > /dev/null; then
        echo "No existing key found. Generating new key..."
        # Stop any running processes first
        screen -S hyperspace -X stuff $'\003'
        sleep 2
        
        # Generate new key
        screen -S hyperspace -X stuff "aios-cli keys generate^M"
        sleep 5
        
        # Wait for key generation
        for i in {1..10}; do
            if find_key_file > /dev/null; then
                echo "Key successfully generated!"
                break
            fi
            if [ $i -eq 10 ]; then
                echo "Failed to generate key after multiple attempts."
                return 1
            fi
            sleep 2
        done
    else
        echo "Existing key found."
    fi
    return 0
}

# ----------------------------
# Hive Allocation
# ----------------------------
echo "Allocating Hive RAM..."
if ! run_with_bashrc "aios-cli hive allocate 9"; then
  echo "Failed to allocate Hive RAM. Checking for daemon issues..."
  
  # Check if daemon needs restart
  if restart_daemon_if_needed; then
    echo "Daemon restarted due to 'Another instance is already running' error."
  fi
  
  echo "Retrying Hive allocation..."
  sleep 5
  run_with_bashrc "aios-cli hive allocate 9"
fi

echo "Checking Hive points..."
run_with_bashrc "aios-cli hive points"

# ----------------------------
# Key Generation and Backup
# ----------------------------
echo "Handling key generation and backup..."

# Create secure backup directory
mkdir -p ~/.hyperspace/secure
chmod 700 ~/.hyperspace/secure

# Ensure key is generated
if ! ensure_key_generated; then
    echo "Warning: Could not ensure key generation. Please check manually."
else
    # Find and backup the key
    key_path=$(find_key_file)
    if [ -n "$key_path" ]; then
        echo "Found key at: $key_path"
        cp "$key_path" ~/.hyperspace/secure/key.pem
        chmod 600 ~/.hyperspace/secure/key.pem
        echo "Key successfully backed up to ~/.hyperspace/secure/key.pem"
        
        # Store key path for later use
        echo "$key_path" > ~/.hyperspace/secure/key_location.txt
    else
        echo "Error: Key file not found after generation. Please check manually."
    fi
fi

# Detach from screen again to continue with the rest of the script
echo "Daemon and model connection running in screen session 'hyperspace'"
echo "You can attach to it anytime with 'screen -r hyperspace'"

# ----------------------------
# Completion Message
# ----------------------------
echo "=============================================="
echo "Setup complete! 🎉"

# More detailed key status message
if [ -f ~/.hyperspace/secure/key.pem ]; then
    echo "Your private key is securely backed up at ~/.hyperspace/secure/key.pem"
    if [ -f ~/.hyperspace/secure/key_location.txt ]; then
        original_location=$(cat ~/.hyperspace/secure/key_location.txt)
        echo "Original key location: $original_location"
    fi
    echo "To view your key, use:"
    echo "  cat ~/.hyperspace/secure/key.pem"
    echo ""
    echo "IMPORTANT: Keep this key safe! It's required to access your node."
else
    echo "WARNING: No private key was found or backed up."
    echo "Please run 'aios-cli keys generate' manually and then"
    echo "copy the key to ~/.hyperspace/secure/key.pem"
fi

echo ""
echo "Thank you for using the Hyperspace Node Setup Script by 0xjay_wins!"
echo "Follow me on X for updates: https://x.com/0xjay_wins"
echo "=============================================="
