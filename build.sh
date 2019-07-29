#!/bin/bash

# This script will build a standalone image for any subfolder, and tag it as latest.

if [ $# -eq 0 ]; then
	echo USAGE: `basename "$0"` <folder> [tag]
	exit 1
elif [ $# -eq 1 ]; then
	tag='latest'
else
	tag=$2
fi

docker build --rm -t ${1%/}:$tag $1
