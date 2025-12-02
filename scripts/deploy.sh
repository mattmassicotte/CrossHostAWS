#!/bin/bash

set -euxo pipefail

bucket=$1

aws lambda update-function-code --function-name CrossHostHTTPLambda  --query FunctionName --publish --s3-bucket $bucket --s3-key CrossHostHTTPLambda.zip
aws lambda update-function-code --function-name CrossHostWSLambda  --query FunctionName --publish --s3-bucket $bucket --s3-key CrossHostWSLambda.zip
aws lambda update-function-code --function-name CrossHostEventLambda   --query FunctionName --publish --s3-bucket $bucket --s3-key CrossHostEventLambda.zip