#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
LOG_FILE="${SCRIPT_DIR}/../mosdns.log"
OUTPUT_FILE="${SCRIPT_DIR}/../output/dns_hijack_results.txt"
HIJACK_FILE="${SCRIPT_DIR}/../rule/dns_hijack.txt"
TMP_FILE=$(mktemp)
CHANGED_FILE=$(mktemp)

[ -f "$LOG_FILE" ] || { echo "Error: $LOG_FILE not found" >&2; exit 1; }
touch "$OUTPUT_FILE" "$HIJACK_FILE"

# 1. 提取日志中包含 dns_hijack 的记录
extract_data() {
  grep -a "dns_hijack" "$LOG_FILE" | while read -r line; do
    domain=$(echo "$line" | awk -F 'QUESTION SECTION:\\\\n;|\\.\\\\' 'NF>1{print $2}')
    ips=$(echo "$line" | awk -F 'tA\\\\t|\\\\n' '{
      for(i=1; i<=NF; i++) {
        if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) print $i
      }
    }' | sort -u | tr '\n' ' ' | sed 's/ *$//')

    [ -n "$domain" ] && [ -n "$ips" ] && echo "$domain $ips"
  done
}

# 2. 提取到临时文件中
extract_data > "$TMP_FILE"

# 3. 遍历 dns_results.txt，保持顺序并合并新 IP（原 IP 在前）
> "$CHANGED_FILE"
while read -r line; do
  orig_domain=$(echo "$line" | awk '{print $1}')
  orig_ips=$(echo "$line" | cut -d' ' -f2-)

  match_line=$(grep -F "$orig_domain " "$TMP_FILE")
  if [ -n "$match_line" ]; then
    new_ips=$(echo "$match_line" | cut -d' ' -f2-)

    # 合并：原 IP 在前，新 IP 在后，去重
    all_ips="$orig_ips $new_ips"
    merged_ips=$(printf "%s\n" $all_ips | awk '!seen[$0]++' | tr '\n' ' ' | sed 's/ *$//')

    if [ "$merged_ips" != "$orig_ips" ]; then
      echo "$orig_domain $merged_ips" >> "$CHANGED_FILE"
      echo "[UPDATED] $orig_domain $merged_ips"
    else
      echo "$line" >> "$CHANGED_FILE"
    fi

    # 从 TMP_FILE 中删除该域名，避免后面重复写入
    grep -vF "$orig_domain " "$TMP_FILE" > "$TMP_FILE.tmp" && mv "$TMP_FILE.tmp" "$TMP_FILE"
  else
    echo "$line" >> "$CHANGED_FILE"
  fi
done < "$OUTPUT_FILE"

# 4. 追加 TMP_FILE 中剩余的新域名记录（新域名）
while read -r new_line; do
  new_domain=$(echo "$new_line" | awk '{print $1}')

  # 确保没写过该域名
  if ! grep -qF "$new_domain " "$CHANGED_FILE"; then
    echo "$new_line" >> "$CHANGED_FILE"
    echo "[NEW-RESULT] $new_line"

    hijack_entry="full:$new_domain"
    if ! grep -qF "$hijack_entry" "$HIJACK_FILE"; then
      echo "$hijack_entry" >> "$HIJACK_FILE"
      echo "[NEW-HIJACK] $hijack_entry"
    fi
  fi
done < "$TMP_FILE"

# 5. 去重域名只保留第一次出现的那一行，保持顺序
TMP_FINAL=$(mktemp)
awk '
{
  if (!seen[$1]++) print $0
}
' "$CHANGED_FILE" > "$TMP_FINAL"

mv "$TMP_FINAL" "$OUTPUT_FILE"
rm -f "$TMP_FILE" "$CHANGED_FILE"

echo "Processing complete. Results in:"
echo "- $OUTPUT_FILE"
echo "- $HIJACK_FILE"
