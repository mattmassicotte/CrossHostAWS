#!/bin/bash

set -euxo pipefail

mkdir -p .build/lambda/layer

pushd .build/lambda/layer

curl https://certs.secureserver.net/repository/sf-class2-root.crt -O
curl https://www.amazontrust.com/repository/AmazonRootCA1.pem -O
cp /Users/matt/Documents/Private/crosshost-rsa-example-private.pem crosshost-rsa.pem
cp /Users/matt/Documents/Private/crosshost-p256-example-private.pem crosshost-p256.pem

cd ..

zip -j CrossHostLambdaLayer.zip layer/*
