#!/bin/bash

set -euxo pipefail

bucket=$1

aws s3 cp ".build/lambda/SocialServerLambda/SocialServerFunction.zip" s3://$bucket/SocialServerFunction.zip