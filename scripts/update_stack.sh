#!/bin/bash

set -euxo pipefail

bucket=$1

aws s3 cp SocialServerLambda.yml s3://$bucket/SocialServerLambda.yml

aws cloudformation update-stack --stack-name SocialServer --template-url https://s3.$AWS_REGION.amazonaws.com/$bucket/SocialServerLambda.yml --capabilities CAPABILITY_NAMED_IAM --parameters "ParameterKey=BucketName,ParameterValue=$bucket" "ParameterKey=Architecture,ParameterValue=arm64"
