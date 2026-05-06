#!/bin/bash

# 递归统计（包含所有子目录）
echo "Recursive directory statistics"
echo "================================"

# 统计文件数量
echo "Total files:"
find ./ -type f | wc -l 

echo

#echo "Total directories:"
echo "Total folders:"
# 不算最顶层目录 # Exclude the top-level directory
find . -mindepth 1 -type d | wc -l


## 建议改进
#files=$(find . -type f | wc -l)
#dirs=$(find . -mindepth 1 -type d | wc -l)
#echo "Files      : $files"
#echo "Directories: $dirs"






# 不递归 # Non-recursive examples:
# find /path/to/dir -maxdepth 1 -type d | wc -l
# find /path/to/dir -maxdepth 1 -type f | wc -l



