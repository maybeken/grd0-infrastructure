.PHONY: build clean

ARCH := $(shell go env GOARCH)
OS := $(shell go env GOOS)

build:
	mkdir -p bin/$(ARCH)
	rm -rf bin/$(ARCH)/proxy
	go build -o bin/$(ARCH)/proxy .

clean:
	rm -rf bin