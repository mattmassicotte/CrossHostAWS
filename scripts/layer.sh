#!/bin/bash

set -euxo pipefail

mkdir -p .build/lambda/layer

pushd .build/lambda/layer

curl https://certs.secureserver.net/repository/sf-class2-root.crt -O
curl https://www.amazontrust.com/repository/AmazonRootCA1.pem -O
cp /Users/matt/Documents/Private/crosshost-example-private.pem crosshost.pem

cd ..

zip -j CrossHostLambdaLayer.zip layer/*
