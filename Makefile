#
# Copyright 2017 Alsanium, SAS. or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

GOPATH ?= $(HOME)/go

TESTS  ?= $(wildcard test/test_*/)
BENCHS ?= $(wildcard bench/bench_*/)

image: clean image-base image-shim

image-base:
	@docker build                                                                \
	  -f src/Dockerfile.base                                                     \
	  -t eawsy/aws-lambda-go-shim:base                                           \
	  .

image-shim: build
	@docker build                                                                \
	  -f src/Dockerfile.shim                                                     \
	  -t eawsy/aws-lambda-go-shim:latest                                         \
	  .

build:
	@mkdir -p dist
	@docker run --rm                                                             \
	  -v $(GOPATH):/go                                                           \
	  -v $(CURDIR):/tmp                                                          \
	  -w /tmp                                                                    \
	  eawsy/aws-lambda-go-shim:base make shim

shim:
	@go build -buildmode=c-shared -ldflags='-w -s' -o dist/runtime.so ./src
	@python -m compileall -q -d runtime src; mv src/*.pyc dist/.
	@cp src/pack.bash dist/pack
	@cp src/version.bash dist/version
	@sed -i "s/VERSION/$(shell date -u +%Y-%m-%d)/g" dist/version
	@chown $(shell stat -c '%u:%g' .) dist/*

test:
	@for test in $(TESTS); do                                                    \
	  cd $$test;                                                                 \
	  $(MAKE) || exit 2;                                                         \
	  unzip -qo *.zip;                                                           \
	  docker run --rm                                                            \
	    -v $(CURDIR)/$$test:/tmp                                                 \
	    -w /tmp                                                                  \
	    amazonlinux:latest python -B -m unittest discover -f || exit 2;          \
	  cd $(CURDIR);                                                              \
	done

bench:
	@for dir in $(BENCHS); do                                                    \
	  FUNCTION_NAME=shim-bench-`date +%s`;                                       \
	  cd $$dir; rm -f runs.txt; $(MAKE);                                         \
	  aws lambda create-function                                                 \
	    --role arn:aws:iam::$(AWS_ACCOUNT_ID):role/lambda_basic_execution        \
	    --function-name $$FUNCTION_NAME                                          \
	    --zip-file fileb://handler.zip                                           \
	    --runtime `cat .runtime | head -1`                                       \
	    --memory-size 128                                                        \
	    --handler `cat .runtime | tail -1` > /dev/null;                          \
	  for run in `seq 1 100`; do                                                 \
	    aws lambda update-function-configuration                                 \
	      --function-name $$FUNCTION_NAME                                        \
	      --environment Variables="{RUN='$$run'}" > /dev/null;                   \
	    aws lambda invoke                                                        \
	      --function-name $$FUNCTION_NAME                                        \
	      --invocation-type RequestResponse                                      \
	      --log-type Tail /dev/null |                                            \
	      jq -r '.LogResult' | base64 -d | grep -o "[0-9\.]\+ ms" |              \
	      head -1 | awk '{print $$1}' >> runs.txt;                               \
	  done;                                                                      \
	  cd $(CURDIR);                                                              \
	done
	@cd bench; ./results.py

clean:
	@rm -rf dist
	@for dir in $(TESTS); do                                                     \
	  cd $$dir;                                                                  \
	  $(MAKE) clean;                                                             \
	  cd $(CURDIR);                                                              \
	done
	@for dir in $(shell ls -d bench/*/); do                                      \
	  cd $$dir;                                                                  \
	  $(MAKE) clean;                                                             \
	  cd $(CURDIR);                                                              \
	done

.PHONY: image image-base image-shim build shim test bench clean
