#!/bin/sh

# ��ȡ�ű�����Ŀ¼
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# ���·������
LOG_FILE="$SCRIPT_DIR/../mosdns.log"
OUTPUT_DIR="$SCRIPT_DIR/../output"
DNS_HIJACK_OUTPUT="$OUTPUT_DIR/dns_hijack.txt"

# �����־�ļ��Ƿ����
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: $LOG_FILE not found." >&2
    exit 1
fi

# �������Ŀ¼����������ڣ�
mkdir -p "$OUTPUT_DIR"

# ��ʼ������ļ���ʹ��touchȷ�����ڣ�
touch "$DNS_HIJACK_OUTPUT"

# ͳ��������������
hijack_added=0

# ���� dns_hijack ��¼
grep "dns_hijack" "$LOG_FILE" | \
awk -F'"qname": "' '{print $2}' | \
awk -F'"' '{print $1}' | \
sed 's/\.$//' | \
sort -u | \
while read -r domain; do
    [ -z "$domain" ] && continue
    
    # ����Ƿ��Ѵ���������ļ���
    if ! grep -qFx "full:$domain" "$DNS_HIJACK_OUTPUT"; then
        echo "full:$domain" >> "$DNS_HIJACK_OUTPUT"
        echo "[+] [DNS Hijack] Added: full:$domain"
        hijack_added=$((hijack_added + 1))
    fi
done

# ������
if [ "$hijack_added" -gt 0 ]; then
    echo "Done. Added $hijack_added hijacked domains to $DNS_HIJACK_OUTPUT"
else
    echo "No new dns_hijack records found in $LOG_FILE."
fi