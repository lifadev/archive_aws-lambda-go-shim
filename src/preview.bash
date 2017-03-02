#!/usr/bin/env bash

#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>
#

function ensure {
  for cmd in $@; do
    command -v $cmd > /dev/null 2>&1 || \
    { echo "I need '$cmd', but it's not available. Aborting." >&2; exit 1; }
  done
}

ensure aws docker go make wget

echo -e "\e[32m> Pull AWS Lambda build environment from Docker Hub\e[0m"

docker pull eawsy/aws-lambda-go-shim:latest

echo
echo -e "\e[32m> Download AWS Lambda Go dependencies from Github\e[0m"

go get -v -u -d github.com/eawsy/aws-lambda-go-core/...

echo
echo -e "\e[32m> Download handy Makefile from Github\e[0m"

wget -O Makefile https://github.com/eawsy/aws-lambda-go-shim/raw/master/src/Makefile.example

echo
echo -e "\e[32m> Check AWS Lambda basic execution role\e[0m"

ROLE_ARN=`aws iam get-role --role-name lambda_basic_execution --query 'Role.Arn' --output text`


if (( $? != 0 )); then
echo
echo -e "\e[32m> Create AWS Lambda basic execution role\e[0m"

aws iam create-role                                                            \
  --role-name lambda_basic_execution                                           \
  --assume-role-policy-document '{
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  }' || exit 1

aws iam attach-role-policy                                                     \
  --role-name lambda_basic_execution                                           \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole\
  || exit 1

ROLE_ARN=`aws iam get-role --role-name lambda_basic_execution --query 'Role.Arn' --output text`
fi

echo
echo -e "\e[32m> Build AWS Lambda function\e[0m"

make || exit 1

echo
echo -e "\e[32m> Deploy AWS Lambda function\e[0m"

aws lambda create-function                                                     \
  --function-name golang-preview                                               \
  --zip-file fileb://handler.zip                                               \
  --role $ROLE_ARN                                                             \
  --runtime python2.7                                                          \
  --handler handler.Handle || exit 1

echo
echo -e "\e[32m> Invoke AWS Lambda function\e[0m"

aws lambda invoke                                                              \
  --function-name golang-preview                                               \
  --invocation-type RequestResponse                                            \
  --log-type Tail  /dev/stderr                                                 \
  --query 'LogResult'                                                          \
  --output text |                                                              \
  base64 -d | grep -o "[0-9\.]\+ ms" | head -1 | xargs -0 echo -n " executed in"
