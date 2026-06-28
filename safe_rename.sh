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
#LOG_FILE="rename_log.txt"
LOG_FILE="rename_log_$(date +%Y%m%d_%H%M%S).txt"
RENAME_COUNT=0

# -----------------------------
# 使用提示
# -----------------------------
usage() {
    echo "Usage: $0 [-n] [-r] [-l logfile] <top_directory>"
    echo
    echo "  -n           dry-run mode (default)"
    echo "  -r, --run    really rename files"
    echo "  -l logfile   specify log file"
    echo
    echo "Examples:"
    echo "  $0 /mnt/ntfs_disk"
    echo "  $0 -n /mnt/ntfs_disk"
    echo "  $0 -r /mnt/ntfs_disk"
    echo "  $0 -r -l mylog.txt /mnt/ntfs_disk"
    exit 1
}

if [ "$1" = "--run" ]; then
    DRY_RUN=0
    shift
fi

# -----------------------------
# 解析参数
# -----------------------------
while getopts ":nrl:" opt; do
    case $opt in
        n)
            DRY_RUN=1
            ;;
        r)
            DRY_RUN=0
            ;;
        l)
            LOG_FILE="$OPTARG"
            ;;
        \?)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

TOP_DIR="$1"
# 自动生成时间戳日志, 不会覆盖历史日志
#if [ -z "$LOG_FILE" ]; then
#    LOG_FILE="rename_log_$(date +%Y%m%d_%H%M%S).txt"
#fi

[ -z "$TOP_DIR" ] && usage
[ ! -d "$TOP_DIR" ] && echo "Error: $TOP_DIR is not a directory" && exit 1

# -----------------------------
# 初始化日志
# -----------------------------
{
    echo "Rename Log - $(date)"
    echo "Top directory: $TOP_DIR"
    echo "Dry run: $DRY_RUN"
    echo "-----------------------------------"
} >> "$LOG_FILE"

# -----------------------------
# 主逻辑
# -----------------------------
#find "$TOP_DIR" -depth -print0 | while IFS= read -r -d '' path; do
while IFS= read -r -d '' path; do

    # 跳过顶层目录本身
    if [ "$path" = "$TOP_DIR" ]; then
        continue
    fi

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
#    base="${base//\;/_}"
#    base="${base//\/_}"
    base="${base//\;/}"
    base="${base//\/}"

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

    ((RENAME_COUNT++))
done < <(find "$TOP_DIR" -depth -print0)

echo
echo "Rename count: $RENAME_COUNT"
echo "Done. Log saved to $LOG_FILE"






