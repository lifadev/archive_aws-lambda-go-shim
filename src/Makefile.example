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
