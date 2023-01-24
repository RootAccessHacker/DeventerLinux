#!/usr/bin/env bash

# Create SSH ID
echo "Creating an SSH ID..."
ssh-keygen -t rsa -b 4096 -C "$HOSTNAME.ad.harderwijk.local" -N "" -f ~/.ssh/id_rsa <<< "y" 1> /dev/null
echo "SSH ID creation completed"
echo
echo "Copying SSH ID..."
ssh-copy-id "administrator"@"10.0.0.15"
echo "Copying SSH ID completed"
echo
