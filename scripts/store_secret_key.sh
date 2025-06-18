#!/bin/bash

# Check if key name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <key_name>"
  exit 1
fi

KEY_NAME="$1"
SECRETS_DIR="$HOME/.secrets"
KEY_FILE="$SECRETS_DIR/$KEY_NAME.key"

# Create secrets directory if it doesn't exist
mkdir -p "$SECRETS_DIR"

# Set secure permissions for secrets directory
chmod 700 "$SECRETS_DIR"

# Prompt for secret input
echo "Paste the secret for $KEY_NAME (input will be hidden):"
read -s SECRET

# Check if secret is empty
if [ -z "$SECRET" ]; then
  echo "Error: No secret provided"
  exit 1
fi

# Write secret to file
echo "$SECRET" > "$KEY_FILE"

# Set secure permissions for key file
chmod 600 "$KEY_FILE"

echo "Secret stored securely in $KEY_FILE"