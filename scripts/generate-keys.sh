#!/bin/bash

# Create keys directory if it doesn't exist
mkdir -p keys

# Generate RSA private key (2048 bits)
openssl genrsa -out keys/private.pem 2048

# Generate RSA public key from private key
openssl rsa -in keys/private.pem -pubout -out keys/public.pem

# Set appropriate permissions
chmod 600 keys/private.pem
chmod 644 keys/public.pem

echo "RSA keys generated successfully!"
echo "Private key: keys/private.pem"
echo "Public key: keys/public.pem"
