#!/bin/bash

set -euxo pipefail

bucket=$1

aws lambda update-function-code --function-name CrossHostHTTPLambda --publish --s3-bucket $bucket --s3-key CrossHostHTTPLambda.zip
aws lambda update-function-code --function-name CrossHostWSLambda --publish --s3-bucket $bucket --s3-key CrossHostWSLambda.zip
