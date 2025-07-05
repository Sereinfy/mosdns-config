#!/bin/sh

# 获取脚本所在目录
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 相对路径定义
LOG_FILE="$SCRIPT_DIR/../mosdns.log"
OUTPUT_DIR="$SCRIPT_DIR/../output"
DNS_HIJACK_OUTPUT="$OUTPUT_DIR/dns_hijack.txt"

# 检查日志文件是否存在
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: $LOG_FILE not found." >&2
    exit 1
fi

# 创建输出目录（如果不存在）
mkdir -p "$OUTPUT_DIR"

# 初始化输出文件（使用touch确保存在）
touch "$DNS_HIJACK_OUTPUT"

# 统计新增域名数量
hijack_added=0

# 处理 dns_hijack 记录
grep "dns_hijack" "$LOG_FILE" | \
awk -F'"qname": "' '{print $2}' | \
awk -F'"' '{print $1}' | \
sed 's/\.$//' | \
sort -u | \
while read -r domain; do
    [ -z "$domain" ] && continue
    
    # 检查是否已存在于输出文件中
    if ! grep -qFx "full:$domain" "$DNS_HIJACK_OUTPUT"; then
        echo "full:$domain" >> "$DNS_HIJACK_OUTPUT"
        echo "[+] [DNS Hijack] Added: full:$domain"
        hijack_added=$((hijack_added + 1))
    fi
done

# 输出结果
if [ "$hijack_added" -gt 0 ]; then
    echo "Done. Added $hijack_added hijacked domains to $DNS_HIJACK_OUTPUT"
else
    echo "No new dns_hijack records found in $LOG_FILE."
fi