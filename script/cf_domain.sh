#!/bin/sh

# 获取脚本所在目录（假设放在/etc/mosdns/script/）
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# 相对路径定义（保持您原有的变量结构）
LOG_FILE="$SCRIPT_DIR/../mosdns.log"
OUTPUT_DIR="$SCRIPT_DIR/../output"  # 单独定义output目录
CLOUDFLARE_OUTPUT="$OUTPUT_DIR/cloudflare_best.txt" 
AKAMAI_OUTPUT="$OUTPUT_DIR/best_akamai.txt"

# 检查日志文件
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: $LOG_FILE not found." >&2
    exit 1
fi

# 创建输出目录（原mkdir逻辑保持不变）
mkdir -p "$OUTPUT_DIR"

# 初始化输出文件（原touch逻辑保持不变）
touch "$CLOUDFLARE_OUTPUT"
touch "$AKAMAI_OUTPUT"

# 统计变量（原样保留）
cloudflare_added=0
akamai_added=0

# 处理cloudflare_best（原样保留）
grep "cloudflare_best" "$LOG_FILE" | \
awk -F'"qname": "' '{print $2}' | \
awk -F'"' '{print $1}' | \
sed 's/\.$//' | \
sort -u | \
while read -r domain; do
    [ -z "$domain" ] && continue
    
    if ! grep -qFx "$domain" "$CLOUDFLARE_OUTPUT"; then
        echo "$domain" >> "$CLOUDFLARE_OUTPUT"
        echo "[+] [Cloudflare] Added: $domain"
        cloudflare_added=$((cloudflare_added + 1))
    fi
done

# 处理best_akamai（原样保留）
grep "best_akamai" "$LOG_FILE" | \
awk -F'"qname": "' '{print $2}' | \
awk -F'"' '{print $1}' | \
sed 's/\.$//' | \
sort -u | \
while read -r domain; do
    [ -z "$domain" ] && continue
    
    if ! grep -qFx "$domain" "$AKAMAI_OUTPUT"; then
        echo "$domain" >> "$AKAMAI_OUTPUT"
        echo "[+] [Akamai] Added: $domain"
        akamai_added=$((akamai_added + 1))
    fi
done

# 输出结果（原样保留）
if [ "$cloudflare_added" -gt 0 ]; then
    echo "Done. Added $cloudflare_added new domains to $CLOUDFLARE_OUTPUT"
else
    echo "No new cloudflare_best domains found in $LOG_FILE."
fi

if [ "$akamai_added" -gt 0 ]; then
    echo "Done. Added $akamai_added new domains to $AKAMAI_OUTPUT"
else
    echo "No new best_akamai domains found in $LOG_FILE."
fi