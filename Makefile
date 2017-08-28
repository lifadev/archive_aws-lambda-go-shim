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

TESTS  ?= $(patsubst tests/%,%,$(wildcard tests/*))
BENCHS ?= $(patsubst benchs/%,%,$(dir $(wildcard benchs/*/)))
CLEAN_TESTS = $(patsubst %,%.clean,$(TESTS))
CLEAN_BENCHS = $(patsubst %,%.clean,$(BENCHS))

image: clean image-base image-shim

.PHONY: image

image-base:
	@docker build                                                                \
	  -f src/Dockerfile.base                                                     \
	  -t eawsy/aws-lambda-go-shim:base                                           \
	  .

.PHONY: image-base

image-shim: build
	@docker build                                                                \
	  -f src/Dockerfile.shim                                                     \
	  -t eawsy/aws-lambda-go-shim:latest                                         \
	  .

.PHONY: image-shim

build:
	@mkdir -p dist
	@docker run --rm                                                             \
	  -e GOPATH=$(GOPATH)                                                        \
	  $(foreach GP,$(subst :, ,$(GOPATH)),-v $(GP):$(GP))                        \
	  -v $(CURDIR):$(CURDIR)                                                     \
	  -w $(CURDIR)                                                               \
	  eawsy/aws-lambda-go-shim:base make shim

.PHONY: build

shim:
	@go build -buildmode=c-shared -ldflags='-w -s' -o dist/runtime.so ./src
	@python -m compileall -q -d runtime src; mv src/*.pyc dist/.
	@cp src/pack.bash dist/pack
	@cp src/version.bash dist/version
	@sed -i "s/VERSION/$(shell date -u +%Y-%m-%d)/g" dist/version
	@chown $(shell stat -c '%u:%g' .) dist/*

.PHONY: shim

test: $(TESTS)

.PHONY: test

$(TESTS):
	@cd tests/$@;                                                                \
	$(MAKE) || exit 2;                                                           \
	unzip -qo *.zip;                                                             \
	for i in $(shell seq 1 $(shell cat tests/$@/.run 2>/dev/null || echo 1)); do \
	  docker run --rm                                                            \
	    -e GOPATH=$(GOPATH)                                                      \
	    $(foreach GP,$(subst :, ,$(GOPATH)),-v $(GP):$(GP))                      \
	    -v $(CURDIR):$(CURDIR)                                                   \
	    -w $(CURDIR)/tests/$@                                                    \
	    amazonlinux:latest python -B -m unittest discover -f || exit 2;          \
	done

bench: $(BENCHS)
	@cd benchs; ./results.py

.PHONY: bench

$(BENCHS):
	@FUNCTION_NAME=shim-bench-`date +%s`;                                        \
	cd benchs/$@; rm -f runs.txt; $(MAKE);                                       \
	aws lambda create-function                                                   \
	  --role arn:aws:iam::$(AWS_ACCOUNT_ID):role/lambda_basic_execution          \
	  --function-name $$FUNCTION_NAME                                            \
	  --zip-file fileb://handler.zip                                             \
	  --runtime `cat .runtime | head -1`                                         \
	  --memory-size 128                                                          \
	  --handler `cat .runtime | tail -1` > /dev/null;                            \
	for run in `seq 1 100`; do                                                   \
	  aws lambda update-function-configuration                                   \
	    --function-name $$FUNCTION_NAME                                          \
	    --environment Variables="{RUN='$$run'}" > /dev/null;                     \
	  aws lambda invoke                                                          \
	    --function-name $$FUNCTION_NAME                                          \
	    --invocation-type RequestResponse                                        \
	    --log-type Tail /dev/null |                                              \
	    jq -r '.LogResult' | base64 -d | grep -o "[0-9\.]\+ ms" |                \
	    head -1 | awk '{print $$1}' >> runs.txt;                                 \
	done

clean: $(CLEAN_TESTS) $(CLEAN_BENCHS)

.PHONY: clean

$(CLEAN_TESTS):
	@cd tests/$(patsubst %.clean,%,$@);                                          \
	$(MAKE) clean;                                                               \
	rm -rf handler

$(CLEAN_BENCHS):
	@cd benchs/$(patsubst %.clean,%,$@);                                         \
	$(MAKE) clean
