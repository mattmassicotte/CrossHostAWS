#!/bin/bash

set -euxo pipefail

swiftly run swift build --product CrossHostAWS -c release -Xlinker -s --swift-sdk aarch64-swift-linux-musl

target=.build/lambda/CrossHostLambda

rm -rf "$target"
mkdir -p "$target"
cp ".build/release/CrossHostAWS" "$target/CrossHostLambda"
cd "$target"
ln -s "CrossHostLambda" "bootstrap"
zip --symlinks CrossHostLambda.zip *
