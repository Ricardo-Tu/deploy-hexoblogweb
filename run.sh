#!/bin/bash
#

docker buildx build -f Dockerfile -t web:1.0 .

docker run -p  10086:4000 \
    -d \
    --name myweb \
    web:1.0 
