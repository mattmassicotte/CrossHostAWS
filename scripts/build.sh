#!/bin/bash

set -euxo pipefail

swiftly run swift build --product SocialServerLambda -c release -Xlinker -S --swift-sdk aarch64-swift-linux-musl

target=.build/lambda/SocialServerLambda

rm -rf "$target"
mkdir -p "$target"
cp ".build/release/SocialServerLambda" "$target/"
cd "$target"
ln -s "SocialServerLambda" "bootstrap"
zip --symlinks SocialServerFunction.zip *
