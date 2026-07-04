
#!/bin/bash

# =============================
# NTFS 安全重命名脚本
# =============================
# 功能：
# 1. 去掉文件/目录名前导/尾部空格,可选递归
# 2. 替换 NTFS 禁止字符 : * ? " < > | 为 _
# 3. 删除控制字符 ASCII 0~31
# 4. 专门处理扩展名：去除扩展名内部及周边的空格
# 5. 去掉末尾空格和 .
# 6. 重名自动添加 _1
# 7. 超长文件名跳过
# 8. 支持 dry-run
# 9. 记录修改日志

# -----------------------------
# 配置
# -----------------------------
MAX_NAME_LEN=255
DRY_RUN=1   # 1 = dry run, 0 = 执行改名
RECURSIVE=0 # 0 = 非递归(默认), 1 = 递归
LOG_FILE="rename_log_$(date +%Y%m%d_%H%M%S).txt"
RENAME_COUNT=0

# -----------------------------
# 使用提示
# -----------------------------
usage() {
    echo "Usage: $0 [-n] [-r] [-R] [-l logfile] <top_directory>"
    echo
    echo "  -n           dry-run mode (default)"
    echo "  -r, --run    really rename files"
    echo "  -R           enable recursive processing of subdirectories (default is off)"
    echo "  -l logfile   specify log file"
    echo
    echo "Examples:"
    echo "  $0 /mnt/ntfs_disk          (Non-recursive, dry-run)"
    echo "  $0 -R /mnt/ntfs_disk       (Recursive, dry-run)"
    echo "  $0 -r -R /mnt/ntfs_disk    (Recursive, execute)"
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
while getopts ":nrl:R" opt; do
    case $opt in
        n)
            DRY_RUN=1
            ;;
        r)
            DRY_RUN=0
            ;;
        R)
            RECURSIVE=1
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

[ -z "$TOP_DIR" ] && usage
# 确保传入的是绝对路径或相对路径的有效目录，方便后续处理
if [ ! -d "$TOP_DIR" ]; then
    echo "Error: $TOP_DIR is not a directory"
    exit 1
fi

# 规范化路径，去掉末尾可能的斜杠，避免 basename/dirname 行为不一致
TOP_DIR="${TOP_DIR%/}"

# -----------------------------
# 初始化日志
# -----------------------------
{
    echo "Rename Log - $(date)"
    echo "Top directory: $TOP_DIR"
    echo "Dry run: $DRY_RUN"
    echo "Recursive: $RECURSIVE"
    echo "-----------------------------------"
} >> "$LOG_FILE"

# -----------------------------
# 核心清理函数
# -----------------------------
clean_name() {
    local input="$1"
    local base="$input"
    
    # 1. 分离扩展名和主体
    # 注意：如果文件名以 . 开头且没有其他 . (如 .gitignore)，basename 会认为没有扩展名
    # 如果文件名有多个 . (如 file.tar.gz)，我们通常只处理最后一个 . 之后的部分作为扩展名
    
    local name_part=""
    local ext_part=""
    
    # 检查是否有扩展名 (包含点号)
    if [[ "$base" == *.* ]]; then
        # 提取最后一个点之后的内容作为扩展名
        ext_part="${base##*.}"
        # 提取最后一个点之前的内容作为主体
        name_part="${base%.*}"
        
        # 特殊情况：如果主体为空（例如文件名为 ".txt"），name_part 为空，ext_part 为 "txt"
        # 此时 name_part 应该视为空，或者根据需求保留点。这里假设 .txt 的主体是空字符串。
    else
        name_part="$base"
        ext_part=""
    fi

    # 2. 清理主体部分 (name_part)
    # 去除前导空白 (包括空格和Tab)
    name_part="${name_part#"${name_part%%[![:space:]]*}"}"
    # 去除尾部空白
    name_part="${name_part%"${name_part##*[![:space:]]}"}"
    # 删除控制字符 ASCII 0~31
    name_part=$(printf '%s' "$name_part" | tr -d '\000-\037')
    # 替换 NTFS 禁止字符
    name_part="${name_part//:/_}"
    name_part="${name_part//\*/_}"
    name_part="${name_part//\?/_}"
    name_part="${name_part//\"/_}"
    name_part="${name_part//</_}"
    name_part="${name_part//>/_}"
    name_part="${name_part//|/_}"
    name_part="${name_part//\;/}" # 删除分号
    name_part="${name_part//$'\x7f'/}" # 删除 DEL 字符

    # 3. 清理扩展名部分 (ext_part)
    if [ -n "$ext_part" ]; then
        # 去除扩展名的前导空格
        ext_part="${ext_part#"${ext_part%%[![:space:]]*}"}"
        # 去除扩展名的尾部空格
        ext_part="${ext_part%"${ext_part##*[![:space:]]}"}"
        # 扩展名中通常不允许有空格或特殊字符，这里也做同样的非法字符清理
        ext_part=$(printf '%s' "$ext_part" | tr -d '\000-\037')
        ext_part="${ext_part//:/_}"
        ext_part="${ext_part//\*/_}"
        ext_part="${ext_part//\?/_}"
        ext_part="${ext_part//\"/_}"
        ext_part="${ext_part//</_}"
        ext_part="${ext_part//>/_}"
        ext_part="${ext_part//|/_}"
        ext_part="${ext_part//\;/}"
        ext_part="${ext_part//$'\x7f'/}"
    fi

    # 4. 重新组合
    local candidate=""
    if [ -n "$ext_part" ]; then
        candidate="${name_part}.${ext_part}"
    else
        candidate="$name_part"
    fi

    # 5. 最终收尾清理 (针对 Windows 不允许结尾的空格或 .)
    # 虽然上面已经去除了尾部空格，但以防万一组合后出现异常，或者主体部分清理后剩下了点
    while [[ "$candidate" == *" " ]]; do
        candidate="${candidate% }"
    done
    while [[ "$candidate" == *. ]]; do
        candidate="${candidate%.}"
    done
    
    # 空名保护
    if [ -z "$candidate" ]; then
        candidate="_"
    fi

    echo "$candidate"
}

# -----------------------------
# 重命名单个条目 (文件或目录)
# -----------------------------
rename_item() {
    local path="$1"
    local dir
    local original_base
    local new_base
    local new_path

    dir=$(dirname -- "$path")
    original_base=$(basename -- "$path")
    
    # 调用清理函数获取新名字
    new_base=$(clean_name "$original_base")
    
    # 如果名字没变，跳过
    if [ "$new_base" = "$original_base" ]; then
        return 0
    fi

    new_path="$dir/$new_base"

    # 重名处理
    local counter=1
    local temp_base="$new_base"
    local temp_name
    local temp_ext
    
    # 再次分离以便插入 _1
    if [[ "$temp_base" == *.* ]]; then
        temp_ext=".${temp_base##*.}"
        temp_name="${temp_base%.*}"
    else
        temp_ext=""
        temp_name="$temp_base"
    fi

    while [ -e "$dir/$temp_base" ]; do
        # 如果目标路径就是当前路径本身（大小写敏感文件系统可能不同，但Linux通常区分），则打破循环
        # 注意：在 Linux 上 mv A A 是允许的但无操作，但在重命名逻辑中，如果存在另一个同名文件，则需要改名
        if [ "$dir/$temp_base" = "$path" ]; then
             break
        fi
        
        temp_base="${temp_name}_${counter}${temp_ext}"
        ((counter++))
        
        # 防止无限循环，虽然极少发生
        if [ $counter -gt 1000 ]; then
            echo "ERROR: Too many conflicts for $path" | tee -a "$LOG_FILE"
            return 1
        fi
    done
    
    new_base="$temp_base"
    new_path="$dir/$new_base"

    # 长度检查
    local len=${#new_base}
    if [ "$len" -gt "$MAX_NAME_LEN" ]; then
        echo "SKIP (too long) $path -> $new_path" | tee -a "$LOG_FILE"
        return 1
    fi

    # 执行重命名
    if [ "$DRY_RUN" = "1" ]; then
        echo "DRY RUN: $path -> $new_path" | tee -a "$LOG_FILE"
	# Dry Run 模式下也计数，方便用户知道有多少文件会被影响
        ((RENAME_COUNT++)) 
    else
        if mv -- "$path" "$new_path"; then
            echo "RENAMED: $path -> $new_path" | tee -a "$LOG_FILE"
            ((RENAME_COUNT++))
            # 返回新的路径，以便父级调用者知道路径已变更（主要用于目录重命名后的路径更新）
            echo "$new_path"
            return 0
        else
            echo "FAILED: $path -> $new_path" | tee -a "$LOG_FILE"
            return 1
        fi
    fi
    # Dry run 模式下也返回新路径逻辑上的样子，虽未真正移动
    echo "$new_path"
    return 0
}

# -----------------------------
# 递归处理目录
# -----------------------------
process_directory() {
    local current_dir="$1"
    
    # 1. 先处理当前目录下的所有子项（文件和子目录）
    # 使用 find 获取直接子项，避免递归过深导致的问题，并处理隐藏文件
    # -mindepth 1 -maxdepth 1 确保只处理直接子项
    while IFS= read -r -d '' item; do
        if [ -d "$item" ]; then
            # 只有当 RECURSIVE 为 1 时才递归进入子目录
            if [ "$RECURSIVE" -eq 1 ]; then
                process_directory "$item"
            else
                echo "SKIP DIR (non-recursive): $item" | tee -a "$LOG_FILE"
            fi
        elif [ -f "$item" ]; then
            # 如果是文件，直接重命名
            #rename_item "$item" > /dev/null
	    rename_item "$item"
        fi
    done < <(find "$current_dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

    # 2. 子项处理完毕后，再重命名当前目录本身
    # 注意：不要重命名顶层目录 TOP_DIR，否则脚本后续可能找不到路径或造成混淆
    if [ "$current_dir" != "$TOP_DIR" ]; then
        # 重命名目录
        # rename_item 会输出新的路径（如果发生了重命名）
        local new_dir_path
        new_dir_path=$(rename_item "$current_dir")
        
        # 如果发生了重命名，new_dir_path 不为空且不等于原路径
        if [ -n "$new_dir_path" ] && [ "$new_dir_path" != "$current_dir" ]; then
            # 这里不需要额外操作，因为 rename_item 已经执行了 mv
            # 但为了逻辑严谨，如果是在非 dry-run 模式下，后续如果有基于此目录的操作需要注意
            :
        fi
    fi
}

# -----------------------------
# 主逻辑入口
# -----------------------------
echo "Starting processing..."
if [ "$RECURSIVE" -eq 1 ]; then
    echo "Mode: Recursive"
else
    echo "Mode: Non-Recursive (Current directory only)"
fi

process_directory "$TOP_DIR"

echo
echo "Rename count: $RENAME_COUNT"
echo "Done. Log saved to $LOG_FILE"
