#!/bin/sh

LOG_FILE="/etc/mosdns/mosdns.log"
OUTPUT_FILE="/etc/mosdns/cloudflare_best.txt"

# �����־�ļ��Ƿ����
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: $LOG_FILE not found." >&2
    exit 1
fi

# �������ļ������ڣ��򴴽�
touch "$OUTPUT_FILE"

# ͳ��������������
added_count=0

# ��ȡ������־�е���������ȥ�أ�
grep "cloudflare_best" "$LOG_FILE" | \
awk -F'"qname": "' '{print $2}' | \
awk -F'"' '{print $1}' | \
sed 's/\.$//' | \
sort -u | \
while read -r domain; do
    [ -z "$domain" ] && continue
    
    # ����Ƿ��Ѵ����� OUTPUT_FILE ��
    if ! grep -qFx "$domain" "$OUTPUT_FILE"; then
        echo "$domain" >> "$OUTPUT_FILE"
        echo "[+] Added: $domain"  # ��ѡ����ʾ����������
        added_count=$((added_count + 1))
    fi
done

# ���� added_count �ж��Ƿ�������
if [ "$added_count" -gt 0 ]; then
    echo "Done. Added $added_count new domains to $OUTPUT_FILE"
else
    echo "No new domains found in $LOG_FILE."
fi