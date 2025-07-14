#!/bin/bash

set -euxo pipefail

swiftly run swift build --product SocialServerLambda -c release -Xlinker -S --swift-sdk aarch64-swift-linux-musl

rm -rf ".build/lambda/SocialServerLambda"
mkdir -p ".build/lambda/SocialServerLambda"
cp ".build/release/SocialServerLambda" ".build/lambda/SocialServerLambda/"
pushd ".build/lambda/SocialServerLambda"
ln -s "SocialServerLambda" "bootstrap"
zip --symlinks SocialServerFunction.zip *
popd

aws s3 cp ".build/lambda/SocialServerLambda/SocialServerFunction.zip" s3://deploy.massicotte.org/SocialServerFunction.zip
#aws lambda update-function-code --function-name SocialServer --region us-east-1 --publish --s3-bucket deploy.massicotte.org --s3-key SocialServerFunction.zip