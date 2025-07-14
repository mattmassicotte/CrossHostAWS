#!/bin/bash

set -euxo pipefail

bucket=$1

aws lambda update-function-code --function-name SocialServer --publish --s3-bucket $bucket --s3-key SocialServerFunction.zip
