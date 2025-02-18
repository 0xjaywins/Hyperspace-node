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
# Initialize daemon directly without screen
# ----------------------------
echo "Starting daemon directly (without screen)..."
run_with_bashrc "aios-cli start" &
sleep 10  # Give it time to start

# ----------------------------
# Model Setup
# ----------------------------
echo "Installing Mistral-7B model..."
# Try multiple times in case of failure
MAX_ATTEMPTS=3
for i in $(seq 1 $MAX_ATTEMPTS); do
  if run_with_bashrc "aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf"; then
    echo "Model installed successfully on attempt $i."
    break
  else
    echo "Failed to install model on attempt $i of $MAX_ATTEMPTS."
    if [ $i -eq $MAX_ATTEMPTS ]; then
      echo "Max attempts reached. Moving on..."
    else
      echo "Waiting before retrying..."
      sleep 10
    fi
  fi
done

# ----------------------------
# Connection
# ----------------------------
echo "Connecting to the model..."
# Try multiple times in case of failure
for i in $(seq 1 $MAX_ATTEMPTS); do
  if run_with_bashrc "aios-cli start --connect"; then
    echo "Connection established successfully on attempt $i."
    break
  else
    echo "Failed to connect on attempt $i of $MAX_ATTEMPTS."
    if [ $i -eq $MAX_ATTEMPTS ]; then
      echo "Max attempts reached. Moving on..."
    else
      echo "Killing daemon and retrying..."
      run_with_bashrc "aios-cli kill" || true
      sleep 5
      run_with_bashrc "aios-cli start" &
      sleep 10
    fi
  fi
done

# ----------------------------
# Verify Connection
# ----------------------------
echo "Verifying connection status..."
if run_with_bashrc "aios-cli status | grep -q connected"; then
  echo "Successfully connected to model."
else
  echo "Warning: Could not verify connection. Continuing anyway..."
fi

# ----------------------------
# Hive Allocation
# ----------------------------
echo "Allocating Hive RAM..."
if ! run_with_bashrc "aios-cli hive allocate 9"; then
  echo "Failed to allocate Hive RAM. Retrying..."
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

# ----------------------------
# Create a screen session at the end for monitoring
# ----------------------------
echo "Creating a screen session for monitoring the daemon..."
run_with_bashrc "screen -S hyperspace -dm bash -c 'aios-cli start --connect; exec bash'"
echo "Screen session 'hyperspace' created. You can attach to it with 'screen -r hyperspace'"

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
