#!/bin/bash

set -euxo pipefail

swiftly run swift build -c release -Xlinker -s --swift-sdk aarch64-swift-linux-musl

rm -rf ".build/lambda"

# prepare HTTP lambda
mkdir -p ".build/lambda/CrossHostHTTPLambda"
cp ".build/release/CrossHostAWS" ".build/lambda/CrossHostHTTPLambda/CrossHostHTTPLambda"
pushd ".build/lambda/CrossHostHTTPLambda"
ln -s "CrossHostHTTPLambda" "bootstrap"
zip --symlinks CrossHostHTTPLambda.zip *
popd

# prepare WS lambda
mkdir -p ".build/lambda/CrossHostWSLambda"
cp ".build/release/CrossHostWS" ".build/lambda/CrossHostWSLambda/CrossHostWSLambda"
pushd ".build/lambda/CrossHostWSLambda"
ln -s "CrossHostWSLambda" "bootstrap"
zip --symlinks CrossHostWSLambda.zip *
popd