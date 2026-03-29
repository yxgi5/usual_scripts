#!/bin/bash

for folders in `ls -l .. |grep ^d |awk '{print substr($0,index($0,$9))}' | grep -e git$`
do 
echo ../$folders
cd ../$folders && git pull
cd $PWD
done
