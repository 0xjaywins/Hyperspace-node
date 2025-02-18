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
# Security Disclaimer
# ----------------------------
echo "WARNING: This script will handle your private keys. Ensure you trust the source of this script."
read -p "Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

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
rm -rf ~/.hyperspace ~/.cache/hyperspace

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
# Installation
# ----------------------------
echo "Installing Hyperspace..."
if ! curl -s https://download.hyper.space/api/install | bash; then
  echo "Failed to install Hyperspace. Please check your internet connection."
  exit 1
fi

# Verify installation
if ! command -v aios-cli &> /dev/null; then
  echo "Failed to install aios-cli. Installation script did not complete successfully."
  exit 1
fi

# ----------------------------
# Screen Session Setup
# ----------------------------
echo "Creating secure screen session and starting daemon..."
screen -S hyperspace -dm bash -c "aios-cli start; exec bash"

# Wait for daemon to start
echo "Waiting for daemon to start..."
sleep 5

# Detach from screen
echo "Detaching from screen session..."
screen -d -S hyperspace 2>/dev/null || true

# ----------------------------
# Model Setup
# ----------------------------
echo "Installing Mistral-7B model..."
if ! aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf; then
  echo "Failed to install model. Retrying..."
  sleep 5
  aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf
fi

# ----------------------------
# Connection
# ----------------------------
echo "Reattaching to screen session to connect to model..."
screen -S hyperspace -X stuff "^C"  # Cancel logs (Ctrl+C)
screen -S hyperspace -X stuff "aios-cli start --connect\n"

echo "Waiting for connection to establish..."
sleep 30

# Verify connection with retries
MAX_RETRIES=3
RETRY_COUNT=0
while ! aios-cli status | grep -q "connected"; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
    echo "Failed to connect after $MAX_RETRIES attempts. Please check your configuration."
    exit 1
  fi
  echo "Connection failed. Retrying attempt $RETRY_COUNT of $MAX_RETRIES..."
  aios-cli kill
  sleep 5
  screen -S hyperspace -X stuff "aios-cli start --connect\n"
  sleep 30
done

echo "Connection established successfully!"

# Detach from screen again
echo "Detaching from screen session..."
screen -d -S hyperspace 2>/dev/null || true

# ----------------------------
# Hive Allocation
# ----------------------------
echo "Allocating Hive RAM..."
if ! aios-cli hive allocate 9; then
  echo "Failed to allocate Hive RAM. Retrying..."
  sleep 5
  aios-cli hive allocate 9
fi

echo "Checking Hive points..."
aios-cli hive points

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
