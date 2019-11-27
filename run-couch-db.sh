#!/bin/bash

THIS_DIR=$(cd `dirname $0`; pwd)
name=my-couchdb

if [[ $(docker ps -f "name=$name" --format '{{.Names}}') == $name ]] ; then
    echo "Already running"
else
    podman rm my-couchdb
    podman run -d -p 5984:5984 --name $name -v $THIS_DIR/data/couchdb:/opt/couchdb/data  couchdb:latest
fi