#!/usr/bin/env bash

filelist=`ls `

for file in $filelist
do
    echo $file
    docker run -v $(pwd):/tmp mythril/myth analyze /tmp/$file --solv 0.4.25 | tee ../mythlogs/smartcheck_"$file".log;
done