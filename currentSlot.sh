#!/usr/bin/env bash
#
# This script is based of the following guide:
# https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node
#
# Calculates and outputs the current slot number, also writes it to a file.
#
# Place this file in a folder named "rotate-keys" inside your cardano-node user home folder.

# Define path variable
THIS_PATH="$HOME/rotate-keys"

# Export the relevant socket path
export CARDANO_NODE_SOCKET_PATH="$HOME/cardano-my-node/db/socket"

# Use cardano-cli and grep to output the current slot and also save to it the file currentSlot.txt
CURRENT_SLOT=$(/usr/local/bin/cardano-cli shelley query tip --testnet-magic 42 | /usr/bin/grep -oP 'SlotNo = \K\d+')
echo "Current slot: $CURRENT_SLOT"
echo "$CURRENT_SLOT" > "$THIS_PATH/currentSlot.txt"