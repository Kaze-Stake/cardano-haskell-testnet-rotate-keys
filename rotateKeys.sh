#!/usr/bin/env bash
#
# This script is based of the following guide:
# https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node
#
# Rotates KES keys and restarts the block producing node when the time comes.
#
# Place this file in a folder named "rotate-keys" inside your cardano-node user home folder.
#
# IMPORTANT: Run forceRotateKeys.sh if the file renewPeriod.txt doesn't exist yet
#
# Line 14 should be added to "crontab -e"
: <<'COMMENT'
0 * * * * /usr/bin/bash ${HOME}/rotate-keys/rotateKeys.sh
COMMENT

# Define path variables
THIS_PATH="$HOME/rotate-keys"
NODE_PATH="$HOME/cardano-my-node"
COLD_PATH="$HOME/cold-keys"

# Export the relevant socket path
export CARDANO_NODE_SOCKET_PATH="$NODE_PATH/db/socket"

# Runs the block producing node in a tmux session and uses port 3000 by default
SESSION="block_producer"
PORT=3000

# Calculates the current slot, the current KES period, and the next KES period to rotate the keys
CURRENT_SLOT=$(/usr/local/bin/cardano-cli shelley query tip --testnet-magic 42 | grep -oP 'SlotNo = \K\d+')
KES_PERIOD=$(expr $CURRENT_SLOT / 3600)
NEXT_KES_PERIOD=$(expr $KES_PERIOD + 119)

# Gets the previously logged KES period to know when it is time to renew
RENEW_KES_PERIOD=$(cat $THIS_PATH/renewPeriod.txt)

# Compares the current KES period to the logged KES period
if [ $KES_PERIOD -ge $RENEW_KES_PERIOD ]
then
    # Unlocks the cold-keys path, rotates the KES keys, locks the cold-keys path
    chmod u+rwx $COLD_PATH
    cardano-cli shelley node issue-op-cert \
        --kes-verification-key-file $NODE_PATH/kes.vkey \
        --cold-signing-key-file $COLD_PATH/node.skey \
        --operational-certificate-issue-counter $COLD_PATH/node.counter \
        --kes-period $KES_PERIOD \
        --out-file $NODE_PATH/node.cert
    chmod a-rwx $COLD_PATH
    
    # Saves the next KES period to the file renewPeriod.txt
    echo "$NEXT_KES_PERIOD" > "$THIS_PATH/renewPeriod.txt"
    
    # Kill the block producing node and restarts it in a new tmux session
    kill $(lsof -i:$PORT -sTCP:LISTEN)
    tmux has-session -t $SESSION 2>/dev/null
    if [ $? != 0 ]
    then
        tmux new-session -d -s $SESSION "sh $NODE_PATH/startBlockProducingNode.sh"
    else
        tmux kill-session -t $SESSION
        tmux new-session -d -s $SESSION "sh $NODE_PATH/startBlockProducingNode.sh"
    fi
else
    # If it is not yet time to rotate the KES keys; log the remaining time to the file timeLeft.txt
    TIME_LEFT=$(expr 3600 \* $RENEW_KES_PERIOD - $CURRENT_SLOT)
    DAYS_LEFT=$(expr $TIME_LEFT / 86400)
    HOURS_LEFT=$(expr $TIME_LEFT / 3600)
    MINUTES_LEFT=$(expr $TIME_LEFT / 60)
    cat <<EOT > timeLeft.txt
Current KES Period:   ${KES_PERIOD}
Next KES Rotation:    ${RENEW_KES_PERIOD}
Time left:            ${DAYS_LEFT} days, $((${HOURS_LEFT}%24)) hours, $((${MINUTES_LEFT}%60)) minutes
EOT
fi
