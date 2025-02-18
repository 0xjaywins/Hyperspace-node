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
# Function to check if screen session exists
# ----------------------------
check_screen() {
    screen -ls | grep -q "hyperspace"
    return $?
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
if ! command -v aios-cli &> /dev/null; then
  echo "Failed to find aios-cli. The installation may not have completed successfully."
  echo "Make sure to run 'source ~/.bashrc' or start a new terminal session."
  exit 1
fi

# ----------------------------
# Screen Session Setup (Fixed)
# ----------------------------
echo "Starting daemon inside screen session..."
screen -dmS hyperspace bash -c 'aios-cli start; exec bash'  # Start daemon in screen

# Wait until screen session is active
echo "Waiting for daemon to start..."
sleep 10  # Give time for the daemon to fully start

if ! check_screen; then
  echo "Error: Screen session did not start properly."
  exit 1
fi

# ----------------------------
# Connect Model (Using Same Screen Session)
# ----------------------------
echo "Stopping logs inside screen session..."
screen -S hyperspace -X stuff $'\003'  # Send Ctrl+C to stop logs
sleep 2

echo "Connecting model inside the same screen session..."
screen -S hyperspace -X stuff "aios-cli start --connect\n"
sleep 5

echo "Detaching from screen session..."
screen -d hyperspace

echo "Waiting for connection to establish..."
sleep 30

# ----------------------------
# Verify Connection with Retries
# ----------------------------
MAX_RETRIES=3
RETRY_COUNT=0

check_connection() {
  screen -S hyperspace -X stuff "aios-cli status\n"
  sleep 2
  screen -S hyperspace -X hardcopy ~/hyperspace_status.log  # Save output
  grep -q "connected" ~/hyperspace_status.log
  return $?
}

while ! check_connection; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
    echo "Failed to connect after $MAX_RETRIES attempts. Please check logs."
    exit 1
  fi
  echo "Connection failed. Retrying attempt $RETRY_COUNT of $MAX_RETRIES..."

  # Stop any running instance inside the screen
  screen -S hyperspace -X stuff $'\003'  # Stop any running process
  sleep 2
  screen -S hyperspace -X stuff "aios-cli kill\n"
  sleep 5
  screen -S hyperspace -X stuff "aios-cli start --connect\n"
  sleep 5
  screen -S hyperspace -X stuff "exec bash\n"  # Keep screen open
  
  sleep 30
done

echo "Connection established successfully!"

# ----------------------------
# Hive Allocation
# ----------------------------
echo "Allocating Hive RAM..."
if ! screen -S hyperspace -X stuff "aios-cli hive allocate 9\n"; then
  echo "Failed to allocate Hive RAM. Retrying..."
  sleep 5
  screen -S hyperspace -X stuff "aios-cli hive allocate 9\n"
fi

echo "Checking Hive points..."
screen -S hyperspace -X stuff "aios-cli hive points\n"

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
