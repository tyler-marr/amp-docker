#!/bin/bash
if [ $# -eq 0 ]; then
	tag='latest'
else
	tag=$1
fi

docker build --rm -t amplet2:$tag .
