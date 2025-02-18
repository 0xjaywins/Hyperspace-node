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

echo "Starting daemon..."
screen -S hyperspace -X stuff "aios-cli start\n"
sleep 2 && screen -d -S hyperspace

echo "Installing Mistral-7B model..."
aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf

echo "Connecting to model..."
screen -S hyperspace -X stuff "aios-cli start --connect\n"
sleep 20

echo "Allocating Hive RAM..."
aios-cli hive allocate 9

echo "Saving private key..."
[ -f ~/.config/key.pem ] && cp ~/.config/key.pem ~/hyperspace_key.pem

echo "Setup complete! Key saved to ~/hyperspace_key.pem"
aios-cli hive points
