#!/bin/bash

set -euxo pipefail

bucket=$1

aws s3 cp ".build/lambda/CrossHostLambda/CrossHostLambda.zip" s3://$bucket/CrossHostLambda.zip
aws s3 cp ".build/lambda/CrossHostLambdaLayer.zip" s3://$bucket/CrossHostLambdaLayer.zip
