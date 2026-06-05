#!/bin/bash

# =============================
# NTFS 安全重命名脚本
# =============================
# 功能：
# 1. 递归去掉文件/目录名前导空格
# 2. 替换 NTFS 禁止字符 : * ? " < > | 为 _
# 3. 删除控制字符 ASCII 0~31
# 4. 去掉末尾空格和 .
# 5. 重名自动添加 _1
# 6. 超长文件名跳过
# 7. 支持 dry-run
# 8. 记录修改日志 rename_log.txt

# -----------------------------
# 配置
# -----------------------------
MAX_NAME_LEN=255
DRY_RUN=1   # 1 = dry run, 0 = 执行改名
LOG_FILE="rename_log.txt"

# -----------------------------
# 使用提示
# -----------------------------
usage() {
    echo "Usage: $0 [-n] <top_directory>"
    echo "  -n : dry-run mode (默认开启，可查看将要修改的文件名)"
    echo "Example:"
    echo "  $0 -n /mnt/ntfs_disk"
    echo "  $0 /mnt/ntfs_disk        # 执行实际重命名"
    exit 1
}

# -----------------------------
# 解析参数
# -----------------------------
while getopts ":n" opt; do
    case $opt in
        n)
            DRY_RUN=1
            ;;
        \?)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

TOP_DIR="$1"

[ -z "$TOP_DIR" ] && usage
[ ! -d "$TOP_DIR" ] && echo "Error: $TOP_DIR is not a directory" && exit 1

# -----------------------------
# 初始化日志
# -----------------------------
echo "Rename Log - $(date)" > "$LOG_FILE"
echo "Top directory: $TOP_DIR" >> "$LOG_FILE"
echo "Dry run: $DRY_RUN" >> "$LOG_FILE"
echo "-----------------------------------" >> "$LOG_FILE"

# -----------------------------
# 主逻辑
# -----------------------------
find "$TOP_DIR" -depth -print0 |
while IFS= read -r -d '' path; do

    dir=$(dirname -- "$path")
    base=$(basename -- "$path")
    original="$base"

    # 去除前导空格
    base="${base#"${base%%[! ]*}"}"

    # 删除控制字符 ASCII 0~31
    base=$(printf '%s' "$base" | tr -d '\000-\037')

    # 替换 NTFS 禁止字符
    base="${base//:/_}"
    base="${base//\*/_}"
    base="${base//\?/_}"
    base="${base//\"/_}"
    base="${base//</_}"
    base="${base//>/_}"
    base="${base//|/_}"

    # 去掉 Windows 不允许结尾的空格或 .
    while [[ "$base" == *" " ]]; do
        base="${base% }"
    done
    while [[ "$base" == *. ]]; do
        base="${base%.}"
    done

    # 空名保护
    [ -z "$base" ] && base="_"
    
    # 文件名无变化则跳过
    if [ "$base" = "$original" ]; then
        continue
    fi

    # 分离文件名和扩展名
    name="${base%.*}"
    ext="${base##*.}"
    if [[ "$name" == "$ext" ]]; then
        ext=""  # 无扩展名
    else
        ext=".$ext"
    fi

    candidate="$name$ext"
    
    # 如果名称根本没变化，则直接跳过
    if [ "$candidate" = "$original" ]; then
        continue
    fi

    # 重名处理，_1 插入到扩展名前
    while [ -e "$dir/$candidate" ]; do
    
        # 自己本身，不算重名
        if [ "$dir/$candidate" = "$path" ]; then
            break
        fi
        
        name="${name}_1"
        candidate="$name$ext"
    done

    # 长度检查
    len=$(printf '%s' "$candidate" | wc -c)
    if [ "$len" -gt "$MAX_NAME_LEN" ]; then
        echo "SKIP (too long) $path -> $dir/$candidate" | tee -a "$LOG_FILE"
        continue
    fi

    # 执行或 dry-run
    if [ "$DRY_RUN" = "1" ]; then
        echo "DRY RUN: $path -> $dir/$candidate" | tee -a "$LOG_FILE"
    else
        mv -- "$path" "$dir/$candidate"
        echo "RENAMED: $path -> $dir/$candidate" | tee -a "$LOG_FILE"
    fi

done

echo "Done. Log saved to $LOG_FILE"
