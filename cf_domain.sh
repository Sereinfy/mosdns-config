#!/bin/sh

LOG_FILE="/etc/mosdns/mosdns.log"
OUTPUT_FILE="/etc/mosdns/cloudflare_best.txt"

# 检查日志文件是否存在
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: $LOG_FILE not found." >&2
    exit 1
fi

# 如果输出文件不存在，则创建
touch "$OUTPUT_FILE"

# 统计新增域名数量
added_count=0

# 提取本次日志中的新域名（去重）
grep "cloudflare_best" "$LOG_FILE" | \
awk -F'"qname": "' '{print $2}' | \
awk -F'"' '{print $1}' | \
sed 's/\.$//' | \
sort -u | \
while read -r domain; do
    [ -z "$domain" ] && continue
    
    # 检查是否已存在于 OUTPUT_FILE 中
    if ! grep -qFx "$domain" "$OUTPUT_FILE"; then
        echo "$domain" >> "$OUTPUT_FILE"
        echo "[+] Added: $domain"  # 可选：显示新增的域名
        added_count=$((added_count + 1))
    fi
done

# 根据 added_count 判断是否有新增
if [ "$added_count" -gt 0 ]; then
    echo "Done. Added $added_count new domains to $OUTPUT_FILE"
else
    echo "No new domains found in $LOG_FILE."
fi