#!/bin/bash

set -e

BASE_DIR="$(cd .. && pwd)"

for dir in "$BASE_DIR"/*; do
    # 只处理目录
    [ -d "$dir" ] || continue

    # 必须是 git 仓库（有 .git）
    [ -d "$dir/.git" ] || continue

    # 必须有远程仓库
    if ! git -C "$dir" remote | grep -q .; then
        continue
    fi

    # echo "Updating: $dir"
    branch=$(git -C "$dir" branch --show-current)
    echo "Updating: $dir ($branch)"

    git -C "$dir" pull --ff-only || echo "Failed: $dir"
done
