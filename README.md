# Hyperspace-node
## What the Script Does
1. **Cleanup**:
   - Kills existing Hyperspace processes.
   - Removes old screen sessions and config files.
   - Backs up your private key (if it exists) to `~/.hyperspace/secure/key_old.pem`.

2. **Installation**:
   - Downloads and installs Hyperspace.
   - Creates a `screen` session for the Hyperspace daemon.

3. **Model Setup**:
   - Installs the Mistral-7B model from Hugging Face.

4. **Connection**:
   - Reattaches to the screen session, cancels logs, and connects to the model.
   - Detaches from the screen session to keep the daemon running in the background.

5. **Hive Allocation**:
   - Allocates 9 GB of RAM for Hive points (Tier 3).
   - Checks Hive points.

6. **Key Backup**:
   - Saves your new private key to `~/.hyperspace/secure/key.pem`.
