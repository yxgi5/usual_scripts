#!/bin/bash

set -euo pipefail

INNER_PASS="内层密码"
OUTER_PASS="外层密码"

# 遍历当前目录下所有子目录（不递归）
find . -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d '' dir
do
    folder="${dir#./}"

    echo "Processing: $folder"

    INNER_ARCHIVE="${folder}.7z"

    # Step 1: 内层压缩
    7z a -r -t7z -mx9 -aou -p"$INNER_PASS" -mhe=on "$INNER_ARCHIVE" "$folder"

    # Step 2: 分割（dd）
    dd if="$INNER_ARCHIVE" of="${INNER_ARCHIVE}.001" bs=1M count=1
    dd if="$INNER_ARCHIVE" of="${INNER_ARCHIVE}.002" bs=1M skip=1

    # Step 3: 外层加密
    7z a -r -t7z -mx9 -aou -p"$OUTER_PASS" -mhe=on "${folder}_output.7z" \
        "${INNER_ARCHIVE}.001" "${INNER_ARCHIVE}.002"

    # Step 4: 清理中间文件
    rm -f "$INNER_ARCHIVE" "${INNER_ARCHIVE}.001" "${INNER_ARCHIVE}.002"

done

# 统计文件数目
echo "Total files:"
find . -type f | wc -l
