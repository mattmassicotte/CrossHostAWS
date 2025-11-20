#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <rsa-key-path> <p256-key-path>"
	echo ""
	echo "Example:"
	echo "  $0 crosshost-rsa.pem crosshost-p256.pem"
	exit 1
fi

rsapath="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
p256path="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

if [ ! -f "$rsapath" ]; then
	echo "Error: RSA key not found at: $rsapath"
	exit 1
fi

if [ ! -f "$p256path" ]; then
	echo "Error: P256 key not found at: $p256path"
	exit 1
fi

echo "Building Lambda Layer with keys:"
echo "  RSA:  $rsapath"
echo "  P256: $p256path"
echo ""

mkdir -p .build/lambda/layer
pushd .build/lambda/layer > /dev/null

curl https://certs.secureserver.net/repository/sf-class2-root.crt -O
curl https://www.amazontrust.com/repository/AmazonRootCA1.pem -O
cp "$rsapath" crosshost-rsa.pem
cp "$p256path" crosshost-p256.pem

cd ..
zip -j CrossHostLambdaLayer.zip layer/*
popd > /dev/null

echo ""
echo "✓ Lambda layer created: .build/lambda/CrossHostLambdaLayer.zip"
