#!/usr/bin/env bash
#
# This script is based of the following guide:
# https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node
#
# Calculates and outputs the current slot number, also writes it to a file.
#
# Place this file in a folder named "rotate-keys" inside your cardano-node user home folder.

# Define path variables
THIS_PATH="$HOME/rotate-keys"
NODE_PATH="$HOME/cardano-my-node"
GENESIS_PATH="$NODE_PATH/mainnet_candidate-shelley-genesis.json"

# Export the relevant socket path
export CARDANO_NODE_SOCKET_PATH="$HOME/cardano-my-node/db/socket"

# Use cardano-cli and grep to output the current slot and KES period
SLOTS_PER_KES_PERIOD=$(cat $GENESIS_PATH | /usr/bin/grep -oP '"slotsPerKESPeriod": \K\d+')
CURRENT_SLOT=$(/usr/local/bin/cardano-cli shelley query tip --testnet-magic 42 | /usr/bin/grep -oP '"slotNo": \K\d+')
CURRENT_KES_PERIOD=$(expr $CURRENT_SLOT / $SLOTS_PER_KES_PERIOD)
echo "Current slot: $CURRENT_SLOT"
echo "Current KES period: $CURRENT_KES_PERIOD"

# Save output numbers to the files currentSlot.txt and currentKESPeriod.txt
echo "$CURRENT_SLOT" > "$THIS_PATH/currentSlot.txt"
echo "$CURRENT_KES_PERIOD" > "$THIS_PATH/currentKESPeriod.txt"