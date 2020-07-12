#!/usr/bin/env bash
#
# This script is based of the following guide:
# https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node
#
# Calculates and outputs the remaining time until KES keys have to be rotated.
#
# Place this file in a folder named "rotate-keys" inside your cardano-node user home folder.
#
# Assumes that the file renewPeriod.txt already exists (run forceRotateKeys.sh).

# Define path variables
THIS_PATH="$HOME/rotate-keys"
NODE_PATH="$HOME/cardano-my-node"
GENESIS_PATH="$NODE_PATH/mainnet_candidate-shelley-genesis.json"

# Export the relevant socket path
export CARDANO_NODE_SOCKET_PATH="$HOME/cardano-my-node/db/socket"

# Calculates the current slot, the current KES period, and the next KES period to rotate the keys
CURRENT_SLOT=$(cardano-cli shelley query tip --testnet-magic 42 | /usr/bin/grep -oP '"slotNo": \K\d+')
SLOTS_PER_KES_PERIOD=$(cat $NODE_PATH/mainnet_candidate-shelley-genesis.json | /usr/bin/grep -oP '"slotsPerKESPeriod": \K\d+')
KES_PERIOD=$(expr $CURRENT_SLOT / $SLOTS_PER_KES_PERIOD)
NEXT_KES_PERIOD=$(expr $KES_PERIOD + 119)

# Gets the previously logged KES period to know when it is time to renew
RENEW_KES_PERIOD=$(cat $THIS_PATH/renewPeriod.txt)

# Calculates and outputs the remaining time to the terminal
TIME_LEFT=$(expr 3600 \* $RENEW_KES_PERIOD - $CURRENT_SLOT)
DAYS_LEFT=$(expr $TIME_LEFT / 86400)
HOURS_LEFT=$(expr $TIME_LEFT / 3600)
MINUTES_LEFT=$(expr $TIME_LEFT / 60)
echo "Current KES Period:   $KES_PERIOD"
echo "Next KES Rotation:    $RENEW_KES_PERIOD"
echo "Time left:            $DAYS_LEFT days, $(($HOURS_LEFT % 24)) hours, $(($MINUTES_LEFT % 60)) minutes"