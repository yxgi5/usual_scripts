#!/bin/bash

set -euo pipefail

PASSWORD="测试"

# 遍历当前目录下所有子目录（不递归）
find . -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d '' dir
do
    # 去掉 ./ 前缀
    folder="${dir#./}"

    echo "Processing: $folder"

    7z a -r -sdel -t7z -mx9 -aou -p"$PASSWORD" -mhe=on "${folder}.7z" "$folder"
done

# 统计文件数目
echo "Total files:"
find . -type f | wc -l
