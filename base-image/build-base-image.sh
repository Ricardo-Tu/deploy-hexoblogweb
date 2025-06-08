#/bin/bash


docker build -f Dockerfile.base -t mybase:1.0 .
# docker save mybase:1.0 > mybase_1.0.tar
# docker load < mybase_1.0.tar
