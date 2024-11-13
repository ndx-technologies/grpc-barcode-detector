#!/bin/sh

rm -rf pkg
mkdir pkg
protoc --proto_path=proto --go_out=. --go-grpc_out=. $(find proto -iname "*.proto")
