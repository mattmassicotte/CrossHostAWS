#!/bin/bash

set -euxo pipefail

bucket=$1

aws lambda update-function-code --function-name CrossHost --publish --s3-bucket $bucket --s3-key CrossHostLambda.zip
