# Hyperspace CLI Node Setup

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

## Load environment variables
- **You need to run `source /root/.bashrc` before running the One-click command. This will ensure that the $PATH and other environment variables are correctly loaded**


---

# Usage
# One-Click Command
Run the following command in your terminal to download and execute the script:

 ```bash
 curl -sSL https://raw.githubusercontent.com/0xjaywins/Hyperspace-node/refs/heads/main/hyperspace_node.sh | bash
 ```
---
## To check Your accumulated points 
Run the following commands 

 ```bash
 source ~/.bashrc
 aios-cli hive points
 ```
---
## Accessing Your Private Key
Your private key is securely stored at `~/.config/hyperspace/key.pem` To access it:

 **Direct Access**:
  ```bash
   cat ~/.config/hyperspace/key.pem
  ```
---

# Troubleshooting
## Common Issues and Solutions
## 1. Script Fails to Run
- **Cause**: Missing dependencies (``curl` or `screen`).
- **Solution**:Install the required tools:

   ```bash
   sudo apt update && sudo apt install curl screen
   ```

## 2. Insufficient RAM for Hive Allocation
- **Cause**: Your vps/PC doesn’t have enough free RAM.
- **Solution**: Reduce the allocated RAM:

   ```bash
   aios-cli hive allocate 4  # Example: Allocate 4 GB instead of 9
   ```

## 3. Screen Session Issues
- **Cause**: The `screen` session might not be running.
- **Solution**:
  1. Check if the session exists:

     ```bash
      screen -ls
     ```

 2. Reattach to the session:
  
     ```bash
     screen -r hyperspace
    ```

 3. If the session is missing, restart the daemon:

     ```bash
       screen -S hyperspace -dm
       screen -S hyperspace -X stuff "aios-cli start\n"
     ```

## 4. Script Stops Unexpectedly
- **Cause**: The script might have encountered an error.
- **Solution**:
1. Rerun the script:

   ```bash
   ./hyperspace-node.sh
   ```

2. Check the error logs in your terminal for more details.

   ```bash
   screen -r hyperspace
   ```

---

# Support
## For additional help, open an issue in this repository or refer to the [Hyperspace documentation.](https://docs.hyperspace.xyz/)
