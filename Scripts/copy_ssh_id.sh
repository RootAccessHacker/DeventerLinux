#!/usr/bin/env bash

# Copy SSH ID
echo "Copying SSH ID..."
ssh-copy-id "administrator"@"10.0.0.4"
ssh-copy-id "administrator"@"10.0.0.14"
ssh-copy-id "administrator"@"10.0.0.15"
ssh-copy-id "administrator"@"10.0.0.18"
ssh-copy-id "administrator"@"10.0.0.19"
ssh-copy-id "root"@"10.0.0.20"
ssh-copy-id "administrator"@"10.0.0.21"
ssh-copy-id "administrator"@"10.0.0.25"
echo "Copying SSH ID completed"
echo
