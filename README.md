# Hyperspace Node Script

This script automates the setup of a Hyperspace node, including installation, model setup, and Hive allocation. It is designed to be a **one-click solution** for Linux users.

---

## Features
- ✅ **Auto-cleanup**: Removes previous installations and conflicts.
- 🤖 **Model Setup**: Installs the Mistral-7B model automatically.
- 📊 **Hive Allocation**: Allocates RAM for Hive points (Tier 3 by default).
- 🔑 **Key Backup**: Saves your private key securely.

---

## Prerequisites
- **Linux OS**: Tested on Ubuntu/Debian.
- **Dependencies**: Ensure `curl` and `screen` are installed.
- **RAM**: At least 10 GB of free RAM for Hive allocation.
- **Internet**: Stable connection for downloading dependencies.

---

## Usage

### One-Click Command
Run the following command in your terminal to download and execute the script:

```bash
curl -sSL https://raw.githubusercontent.com/0xjaywins/Hyperspace-node/refs/heads/main/hyperspace_node.sh | bash && chmod +x hyperspace_node.sh && ./hyperspace_node.sh

What the Script Does
Cleanup:

Kills existing Hyperspace processes.

Removes old screen sessions and config files.

Backs up your private key (if it exists) to ~/.hyperspace/secure/key_old.pem.

Installation:

Downloads and installs Hyperspace.

Creates a screen session for the Hyperspace daemon.

Model Setup:

Installs the Mistral-7B model from Hugging Face.

Connection:

Connects to the Hyperspace network.

Automatically retries if the connection fails.

Hive Allocation:

Allocates 9 GB of RAM for Hive points (Tier 3).

Key Backup:

Saves your new private key to ~/.hyperspace/secure/key.pem.

Security
Private Key Safety
Your private key is stored in ~/.hyperspace/secure/key.pem with restricted permissions.

Only the owner (you) can access the key.

Accessing Your Private Key
To view your private key, use:

bash
Copy
cat ~/.hyperspace/secure/key.pem
Important Notes
Never share your private key with anyone.

The key is stored securely, but you should still avoid exposing it unnecessarily.

If you lose your key, you will lose access to your node and any associated incentives.

Troubleshooting
Common Issues and Solutions
1. Script Fails to Run
Cause: Missing dependencies (curl or screen).

Solution: Install the required tools:

bash
Copy
sudo apt update && sudo apt install curl screen
2. Model Fails to Connect
Cause: Network issues or insufficient resources.

Solution:

Wait 5 minutes and rerun the script.

Check your internet connection.

Ensure you have enough free RAM (at least 10 GB).

3. Insufficient RAM for Hive Allocation
Cause: Your system doesn’t have enough free RAM.

Solution: Reduce the allocated RAM:

bash
Copy
aios-cli hive allocate 4  # Example: Allocate 4 GB instead of 9
4. Screen Session Issues
Cause: The screen session might not be running.

Solution:

Check if the session exists:

bash
Copy
screen -ls
Reattach to the session:

bash
Copy
screen -r hyperspace
If the session is missing, restart the daemon:

bash
Copy
screen -S hyperspace -dm
screen -S hyperspace -X stuff "aios-cli start\n"
5. Private Key Not Found
Cause: The key might have been moved or deleted.

Solution:

Check the backup key:

bash
Copy
cat ~/.hyperspace/secure/key_old.pem
If no backup exists, you’ll need to generate a new key and reconfigure your node.

6. Script Stops Unexpectedly
Cause: The script might have encountered an error.

Solution:

Rerun the script:

bash
Copy
./hyperspace_setup.sh
Check the error logs in your terminal for more details.

Support
For additional help, open an issue in this repository or refer to the Hyperspace documentation.

License
This script is open-source and available under the MIT License. Feel free to modify and distribute it.

Contributing
If you'd like to contribute, fork this repository and submit a pull request. Contributions are welcome!

Credits
Hyperspace Team: For the Hyperspace node software.

TheBloke: For the Mistral-7B model on Hugging Face.

Copy

