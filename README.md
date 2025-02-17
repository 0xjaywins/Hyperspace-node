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
curl -sSL https://raw.githubusercontent.com/your-username/hyperspace-node-setup/main/hyperspace_setup.sh | bash
