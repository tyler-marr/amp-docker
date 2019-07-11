#!/bin/bash
if [ $# -eq 0 ]; then
	echo USAGE: `basename "$0"` <folder> [tag]
	exit 1
elif [ $# -eq 1 ]; then
	tag='latest'
else
	tag=$2
fi

docker build --rm -t ${1%/}:$tag $1
