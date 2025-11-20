#!/bin/bash

set -e

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <secure-folder-path>"
	echo ""
	echo "Generates RSA-4096 and P256 keys for Lambda deployment"
	echo ""
	echo "Example:"
	echo "  $0 ~/Documents/Private/crosshost-keys"
	exit 1
fi

SECURE_FOLDER="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RSA_KEY="crosshost-rsa.pem"
P256_KEY="crosshost-p256.pem"

echo "CrossHost Key Generation"
echo "========================"
echo ""
echo "Secure folder: $SECURE_FOLDER"
echo "Project root:  $PROJECT_ROOT"
echo ""

mkdir -p "$SECURE_FOLDER"

echo "Generating RSA-4096 key..."
openssl genrsa -out "$SECURE_FOLDER/$RSA_KEY" 4096

echo "Generating P256 (ECDSA) key..."
openssl ecparam -name prime256v1 -genkey -noout -out "$SECURE_FOLDER/$P256_KEY"

echo ""
echo "Verifying RSA key..."
openssl rsa -in "$SECURE_FOLDER/$RSA_KEY" -check -noout

echo "Verifying P256 key..."
openssl ec -in "$SECURE_FOLDER/$P256_KEY" -check -noout

echo ""
echo "Copying keys to project root..."
cp "$SECURE_FOLDER/$RSA_KEY" "$PROJECT_ROOT/$RSA_KEY"
cp "$SECURE_FOLDER/$P256_KEY" "$PROJECT_ROOT/$P256_KEY"

echo ""
echo "✓ Keys generated successfully!"
echo ""
echo "Master copies (secure):"
echo "  $SECURE_FOLDER/$RSA_KEY"
echo "  $SECURE_FOLDER/$P256_KEY"
echo ""
echo "Working copies (project root):"
echo "  $PROJECT_ROOT/$RSA_KEY"
echo "  $PROJECT_ROOT/$P256_KEY"
echo ""
