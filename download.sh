#!/bin/bash

# 使用说明
usage() {
    echo "用法: $0 [选项] URL1 [URL2] [URL3] ..."
    echo ""
    echo "选项:"
    echo "  -p NUM    并发下载数量 (默认: 4)"
    echo "  -d DIR    下载目录 (默认: downloads)"
    echo "  -t SEC    超时时间 (默认: 300秒)"
    echo "  -h        显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 https://example.com/file1.zip https://example.com/file2.zip"
    echo "  $0 -p 2 -d /tmp/downloads https://example.com/file.zip"
    exit 1
}

# 默认参数
PARALLEL_COUNT=4
DOWNLOAD_DIR="downloads"
TIMEOUT=300

# 解析命令行参数
while getopts "p:d:t:h" opt; do
    case $opt in
        p)
            PARALLEL_COUNT="$OPTARG"
            if ! [[ "$PARALLEL_COUNT" =~ ^[0-9]+$ ]] || [ "$PARALLEL_COUNT" -lt 1 ]; then
                echo "错误: 并发数量必须是正整数"
                exit 1
            fi
            ;;
        d)
            DOWNLOAD_DIR="$OPTARG"
            ;;
        t)
            TIMEOUT="$OPTARG"
            if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
                echo "错误: 超时时间必须是正整数"
                exit 1
            fi
            ;;
        h)
            usage
            ;;
        \?)
            echo "无效选项: -$OPTARG" >&2
            usage
            ;;
    esac
done

# 移除已处理的选项参数
shift $((OPTIND-1))

# 检查是否提供了URL
if [ $# -eq 0 ]; then
    echo "错误: 请提供至少一个下载URL"
    usage
fi

# 获取所有URL参数
urls=("$@")

echo "开始并行下载 ${#urls[@]} 个文件，并发数: $PARALLEL_COUNT"
echo "下载目录: $DOWNLOAD_DIR"
echo "========================================"

# 创建下载目录
mkdir -p "$DOWNLOAD_DIR"

# 下载单个文件的函数
download_file() {
    local url="$1"
    local download_dir="$2"
    local timeout="$3"
    local filename=$(basename "$url")
    local output_file="${download_dir}/${filename}"
    
    # 如果文件名为空或只有路径分隔符，生成一个默认名称
    if [ -z "$filename" ] || [ "$filename" = "/" ]; then
        filename="download_$(date +%s)_$(basename "$url" | tr -d '/')"
        output_file="${download_dir}/${filename}"
    fi
    
    echo "开始下载: $filename"
    
    # 使用curl进行206范围请求下载
    local start_time=$(date +%s.%N)
    
    curl -L \
        --range 0- \
        --output "$output_file" \
        --write-out "文件: ${filename}\n状态码: %{http_code}\n实际URL: %{url_effective}\n下载时间: %{time_total}s\n平均速度: %{speed_download} bytes/s (%.2f KB/s)\n下载大小: %{size_download} bytes\n------------------------\n" \
        --progress-bar \
        --connect-timeout 30 \
        --max-time "$timeout" \
        --fail \
        --location \
        --retry 3 \
        --retry-delay 1 \
        "$url" 2>&1
    
    local exit_code=$?
    local end_time=$(date +%s.%N)
    
    if [ $exit_code -eq 0 ] && [ -f "$output_file" ]; then
        local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
        local download_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
        echo "✓ $filename 下载成功 - 文件大小: $file_size bytes"
    else
        echo "✗ $filename 下载失败 (退出码: $exit_code)"
        # 清理失败的文件
        [ -f "$output_file" ] && rm -f "$output_file"
    fi
}

# 导出函数和变量供子进程使用
export -f download_file
export DOWNLOAD_DIR
export TIMEOUT

# 记录开始时间
overall_start=$(date +%s.%N)

# 并行下载所有文件
printf '%s\n' "${urls[@]}" | xargs -n 1 -P "$PARALLEL_COUNT" -I {} bash -c 'download_file "$1" "$2" "$3"' _ {} "$DOWNLOAD_DIR" "$TIMEOUT"

# 计算总下载时间
overall_end=$(date +%s.%N)
overall_time=$(echo "$overall_end - $overall_start" | bc -l 2>/dev/null || echo "N/A")

echo ""
echo "所有下载任务完成！总耗时: ${overall_time}s"

# 显示下载结果统计
echo ""
echo "下载结果统计:"
echo "=================="
success_count=0
total_size=0

for url in "${urls[@]}"; do
    filename=$(basename "$url")
    # 处理空文件名的情况
    if [ -z "$filename" ] || [ "$filename" = "/" ]; then
        # 尝试找到对应的下载文件
        pattern="${DOWNLOAD_DIR}/download_*_$(basename "$url" | tr -d '/')*"
        if ls $pattern 1> /dev/null 2>&1; then
            filename=$(basename $(ls $pattern | head -1))
        fi
    fi
    
    output_file="${DOWNLOAD_DIR}/${filename}"
    if [ -f "$output_file" ]; then
        size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
        echo "✓ $filename - 大小: $size bytes ($(echo "scale=2; $size / 1024" | bc -l 2>/dev/null || echo "?") KB)"
        success_count=$((success_count + 1))
        total_size=$((total_size + size))
    else
        echo "✗ $filename - 下载失败"
    fi
done

echo "=================="
echo "成功: $success_count/${#urls[@]} 个文件"
echo "总大小: $total_size bytes ($(echo "scale=2; $total_size / 1024 / 1024" | bc -l 2>/dev/null || echo "?") MB)"

# 计算平均速度
if [ "$overall_time" != "N/A" ] && [ "$total_size" -gt 0 ]; then
    avg_speed=$(echo "scale=2; $total_size / $overall_time" | bc -l 2>/dev/null)
    if [ -n "$avg_speed" ]; then
        echo "平均总速度: $avg_speed bytes/s ($(echo "scale=2; $avg_speed / 1024" | bc -l) KB/s)"
    fi
fi
