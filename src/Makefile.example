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
HANDLER ?= handler
PACKAGE ?= package

all:
	@docker run --rm \
		-v $(GOPATH):/go -v $(PWD):/tmp \
		-e "HANDLER=$(HANDLER)" -e "PACKAGE=$(PACKAGE)" \
		eawsy/aws-lambda-go-shim make _all

clean: _clean

_all: _clean
	@echo -ne "build..."\\r
	@go build -buildmode=plugin -ldflags='-w -s' -o $(HANDLER).so
	@chown $(shell stat -c '%u:%g' .) $(HANDLER).so
	@echo -ne "build, pack"\\r
	@zip -q $(PACKAGE).zip $(HANDLER).so
	@echo -ne "build, pack, inject"\\r
	@cd /; mv /shim $(HANDLER); zip -q -r /tmp/$(PACKAGE).zip $(HANDLER)
	@chown $(shell stat -c '%u:%g' .) $(PACKAGE).zip
	@echo -ne "build, pack, inject, go!"\\n

_clean:
	@rm -rf $(PACKAGE).zip $(HANDLER).so
