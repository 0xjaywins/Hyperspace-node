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
# Start Daemon in a Screen Session (Keep Screen Alive)
# ----------------------------
echo "Starting daemon inside a screen session..."
# 'while true; do sleep 9999; done' ensures screen won't exit if 'aios-cli start' returns or crashes
screen -dmS hyperspace bash -c 'aios-cli start; while true; do sleep 9999; done'

# Wait a bit for the daemon to start
echo "Waiting for daemon to initialize..."
sleep 10

# ----------------------------
# Install Mistral-7B Model
# ----------------------------
# We do this OUTSIDE the screen session, but the daemon is already running in the background.
echo "Installing Mistral-7B model..."
if ! aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf; then
  echo "Failed to install model. Retrying..."
  sleep 5
  aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf
fi

# ----------------------------
# Connect Model in the Same Screen Session
# ----------------------------
echo "Connecting model inside the same screen session..."
# First, send Ctrl+C to stop the existing logs (if any)
screen -S hyperspace -X stuff $'\003'
sleep 2

# Now run 'aios-cli start --connect' inside the screen
screen -S hyperspace -X stuff "aios-cli start --connect\n"
sleep 5

# Keep the screen alive
screen -S hyperspace -X stuff "exec bash\n"

# Detach from screen (it's still running)
screen -d hyperspace

echo "Waiting for connection to establish..."
sleep 30

# ----------------------------
# Verify Connection (Retries)
# ----------------------------
MAX_RETRIES=3
RETRY_COUNT=0

check_connection() {
  # We'll just check the daemon status outside the screen
  aios-cli status | grep -q "connected"
  return $?
}

while ! check_connection; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
    echo "Failed to connect after $MAX_RETRIES attempts. Please check logs."
    exit 1
  fi

  echo "Connection failed. Retrying attempt $RETRY_COUNT of $MAX_RETRIES..."
  screen -S hyperspace -X stuff $'\003'       # Ctrl+C to stop anything
  sleep 2
  screen -S hyperspace -X stuff "aios-cli kill\n"
  sleep 5
  screen -S hyperspace -X stuff "aios-cli start --connect\n"
  sleep 5
  screen -S hyperspace -X stuff "exec bash\n"
  sleep 30
done

echo "Connection established successfully!"

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
