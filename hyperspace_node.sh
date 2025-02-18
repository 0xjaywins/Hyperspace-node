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

# Backup old key securely
if [ -f ~/.config/key.pem ]; then
  echo "Backing up old key securely..."
  mkdir -p ~/.hyperspace/secure
  chmod 700 ~/.hyperspace/secure
  cp ~/.config/key.pem ~/.hyperspace/secure/key_old.pem
  chmod 600 ~/.hyperspace/secure/key_old.pem
  echo "Old key backed up to ~/.hyperspace/secure/key_old.pem"
  rm ~/.config/key.pem
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

# Kill any existing sessions and processes (already done in cleanup, but just to be sure)
pkill -f "aios-cli" || true
screen -XS hyperspace quit 2>/dev/null || true

# Create a new screen session for the daemon
screen -dmS hyperspace bash -c "source ~/.bashrc && aios-cli start; exec bash"
echo "Daemon started in screen session 'hyperspace'"
sleep 10  # Give it time to initialize

# Check if we need to restart daemon (e.g., if "Another instance is already running")
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

# Check if daemon needs restart before connecting
restart_daemon_if_needed

screen -S hyperspace -X stuff "aios-cli start --connect^M"  # ^M is Enter key
sleep 5

# ----------------------------
# Verify Connection
# ----------------------------
echo "Verifying connection status..."
if run_with_bashrc "aios-cli status | grep -q connected"; then
  echo "Successfully connected to model in screen session."
else
  echo "Warning: Could not verify connection. Checking for daemon issues..."
  
  # Check if daemon needs restart
  if restart_daemon_if_needed; then
    echo "Daemon restarted due to 'Another instance is already running' error."
    echo "Trying to connect again..."
    screen -S hyperspace -X stuff "aios-cli connect^M"
    sleep 5
  else
    echo "Attempting to connect again anyway..."
    screen -S hyperspace -X stuff "aios-cli connect^M"  # Try again
    sleep 5
  fi
  
  # Check again after second attempt
  if ! run_with_bashrc "aios-cli status | grep -q connected"; then
    echo "Warning: Still could not verify connection. Continuing anyway..."
  fi
fi

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
# Key Backup
# ----------------------------
echo "Saving private key securely..."
mkdir -p ~/.hyperspace/secure
chmod 700 ~/.hyperspace/secure
if [ -f ~/.config/key.pem ]; then
  cp ~/.config/key.pem ~/.hyperspace/secure/key.pem
  chmod 600 ~/.hyperspace/secure/key.pem
else
  echo "Warning: key.pem not found in ~/.config/. Please check if key was generated."
fi

# Detach from screen again to continue with the rest of the script
echo "Daemon and model connection running in screen session 'hyperspace'"
echo "You can attach to it anytime with 'screen -r hyperspace'"

# ----------------------------
# Completion Message
# ----------------------------
echo "=============================================="
echo "Setup complete! 🎉"
if [ -f ~/.hyperspace/secure/key.pem ]; then
  echo "Your private key is securely stored at ~/.hyperspace/secure/key.pem."
  echo "To access your key, use:"
  echo "  cat ~/.hyperspace/secure/key.pem"
else
  echo "Note: No private key was found to back up. If this is unexpected,"
  echo "please check the installation logs for errors."
fi
echo ""
echo "Thank you for using the Hyperspace Node Setup Script by 0xjay_wins!"
echo "Follow me on X for updates: https://x.com/0xjay_wins"
echo "=============================================="
