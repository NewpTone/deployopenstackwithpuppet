#!/bin/bash
NAME=gitbook
docker rm -f $NAME &>/dev/null
docker run -t -i -d --name $NAME  -p 80:4000 -v `pwd`:/srv/gitbook fellah/gitbook
