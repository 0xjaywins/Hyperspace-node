#!/bin/bash

# Hyperspace Node Setup Script (Secure and Simple)
# Brought to you by 0xjay_wins 🚀

# ----------------------------
# Source .bashrc
# ----------------------------
echo "Sourcing /root/.bashrc to load environment variables..."
source /root/.bashrc

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

# Install aios-cli
if ! command -v aios-cli &> /dev/null; then
  echo "Installing aios-cli..."
  npm install -g @hyperspace/aios-cli
  echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
fi

# ----------------------------
# Cleanup
# ----------------------------
echo "Cleaning up previous installations..."
pkill -f "aios-cli" || true
screen -XS hyperspace quit || true
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
curl -s https://download.hyper.space/api/install | bash

# ----------------------------
# Screen Session Setup
# ----------------------------
echo "Creating secure screen session and starting daemon..."
SCREEN_SESSION=$(screen -dmS hyperspace bash -c "aios-cli start; exec bash")
echo "Screen session created with ID: $SCREEN_SESSION"

# Detach from screen to install model
echo "Detaching from screen session to install model..."
sleep 2
screen -d "$SCREEN_SESSION"

# ----------------------------
# Model Setup
# ----------------------------
echo "Installing Mistral-7B model..."
aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf

# ----------------------------
# Connection
# ----------------------------
echo "Reattaching to screen session to connect to model..."
screen -r "$SCREEN_SESSION" -X stuff "^C"  # Cancel logs (Ctrl+C)
screen -r "$SCREEN_SESSION" -X stuff "aios-cli start --connect\n"
sleep 20

# Verify connection
if ! aios-cli status | grep -q "connected"; then
  echo "Connection failed. Restarting..."
  aios-cli kill
  screen -r "$SCREEN_SESSION" -X stuff "aios-cli start --connect\n"
  sleep 20
fi

# Detach from screen again
echo "Detaching from screen session..."
screen -d "$SCREEN_SESSION"

# ----------------------------
# Hive Allocation
# ----------------------------
echo "Allocating Hive RAM..."
aios-cli hive allocate 9

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
  echo "WARNING: Private key not found at ~/.config/key.pem. Please check your installation."
fi

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
