#!/bin/bash

set -euxo pipefail

bucket=$1

aws s3 cp ".build/lambda/CrossHostHTTPLambda/CrossHostHTTPLambda.zip" s3://$bucket/CrossHostHTTPLambda.zip
aws s3 cp ".build/lambda/CrossHostWSLambda/CrossHostWSLambda.zip" s3://$bucket/CrossHostWSLambda.zip
aws s3 cp ".build/lambda/CrossHostEventLambda/CrossHostEventLambda.zip" s3://$bucket/CrossHostEventLambda.zip
aws s3 cp ".build/lambda/CrossHostLambdaLayer.zip" s3://$bucket/CrossHostLambdaLayer.zip
