image: base-image shim-image

base-image:
	@docker build \
		-t eawsy/aws-lambda-go-shim:base -f src/Dockerfile.base .

shim-image:
	@docker run \
		--rm -v $(PWD):/tmp -v $(GOPATH):/go -w /tmp eawsy/aws-lambda-go-shim:base \
		go build -buildmode=c-shared -ldflags='-w -s' -o src/shim/shim.so ./src
	@rm -f src/shim/shim.h
	@docker build \
		-t eawsy/aws-lambda-go-shim:latest -f src/Dockerfile.shim .
	@rm -f src/shim/shim.so
