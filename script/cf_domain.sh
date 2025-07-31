#!/bin/sh

# ��ȡ�ű�����Ŀ¼���������/etc/mosdns/script/��
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# ���·�����壨������ԭ�еı����ṹ��
LOG_FILE="$SCRIPT_DIR/../mosdns.log"
OUTPUT_DIR="$SCRIPT_DIR/../output"  # ��������outputĿ¼
CLOUDFLARE_OUTPUT="$OUTPUT_DIR/cloudflare_best.txt" 
AKAMAI_OUTPUT="$OUTPUT_DIR/best_akamai.txt"
Cloudflare_OUTPUT="$OUTPUT_DIR/cloudfront_best.txt"

# �����־�ļ�
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: $LOG_FILE not found." >&2
    exit 1
fi

# �������Ŀ¼��ԭmkdir�߼����ֲ��䣩
mkdir -p "$OUTPUT_DIR"

# ��ʼ������ļ���ԭtouch�߼����ֲ��䣩
touch "$CLOUDFLARE_OUTPUT"
touch "$AKAMAI_OUTPUT"
touch "$Cloudflare_OUTPUT"

# ͳ�Ʊ�����ԭ��������
cloudflare_added=0
akamai_added=0

# ����cloudflare_best��ԭ��������
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

# ����best_akamai��ԭ��������
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

# ����cloudfront_best��ԭ��������
grep "cloudfront_best" "$LOG_FILE" | \
awk -F'"qname": "' '{print $2}' | \
awk -F'"' '{print $1}' | \
sed 's/\.$//' | \
sort -u | \
while read -r domain; do
    [ -z "$domain" ] && continue
    
    if ! grep -qFx "$domain" "$Cloudflare_OUTPUT"; then
        echo "$domain" >> "$Cloudflare_OUTPUT"
        echo "[+] [cloudfront] Added: $domain"
        cloudfront_added=$((cloudfront_added + 1))
    fi
done