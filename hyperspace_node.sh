#!/bin/bash
# Hyperspace Node Setup Script (Secure and Simple)
# Brought to you by 0xjay_wins 🚀

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

# ----------------------------
# Verify Installation
# ----------------------------
echo "Verifying installation..."
if ! command -v aios-cli &> /dev/null; then
  echo "Failed to find aios-cli. The installation may not have completed successfully."
  echo "Make sure to run 'source ~/.bashrc' or start a new terminal session."
  exit 1
fi

# ----------------------------
# Start Daemon in a Screen Session
# ----------------------------
echo "Creating secure screen session and starting daemon..."
screen -dmS hyperspace bash -c 'aios-cli start; exec bash'

# Wait for daemon to start
echo "Waiting for daemon to start..."
sleep 5

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
# Connection Setup (Using Same Screen)
# ----------------------------
echo "Setting up connection inside the existing screen session..."
echo "Stopping logs inside screen session..."
sleep 2

# **Stop the logs inside screen by sending Ctrl+C**
screen -S hyperspace -X stuff $'\003'  
sleep 2  

# **Run the connection inside the same screen**
echo "Starting AIOS connection..."
screen -S hyperspace -X stuff "aios-cli start --connect\n"
sleep 10  # Allow time for connection

# **Check if the connection is successful**
echo "Verifying connection..."
MAX_RETRIES=3
RETRY_COUNT=0

check_connection() {
  aios-cli status | grep -q "connected"
  return $?
}

while ! check_connection; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
    echo "Failed to connect after $MAX_RETRIES attempts. Please check your configuration."
    exit 1
  fi
  echo "Connection failed. Retrying attempt $RETRY_COUNT of $MAX_RETRIES..."

  # **Stop current process inside screen**
  screen -S hyperspace -X stuff $'\003'  # Sends Ctrl+C
  sleep 2

  # **Restart connection inside screen**
  screen -S hyperspace -X stuff "aios-cli start --connect\n"
  sleep 10
done

echo "✅ Connection established successfully!"

# **Detach from the screen (without terminating it)**
screen -d hyperspace
sleep 2

# ----------------------------
# Hive Allocation
# ----------------------------
echo "Allocating Hive RAM..."
screen -S hyperspace -X stuff "aios-cli hive allocate 9\n"
sleep 5

echo "Checking Hive points..."
screen -S hyperspace -X stuff "aios-cli hive points\n"
sleep 5

# **Detach the screen again after Hive allocation**
screen -d hyperspace

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
echo "🎉 Setup complete!"
if [ -f ~/.hyperspace/secure/key.pem ]; then
  echo "🔐 Your private key is securely stored at ~/.hyperspace/secure/key.pem."
  echo "To access your key, use:"
  echo "  cat ~/.hyperspace/secure/key.pem"
else
  echo "⚠️ No private key found to back up. Check installation logs for errors."
fi
echo ""
echo "🚀 Thank you for using the Hyperspace Node Setup Script by 0xjay_wins!"
echo "📢 Follow me on X for updates: https://x.com/0xjay_wins"
echo "=============================================="
