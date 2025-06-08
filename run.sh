#!/bin/bash
#

docker build -f Dockerfile -t web:1.0 .

docker run --restart=always \
    -p 80:4000 \
    -d \
    --name myweb \
    web:1.0 
