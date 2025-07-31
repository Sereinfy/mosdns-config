#!/bin/sh

script_dir="$(cd "$(dirname "$0")" && pwd)"
log_file="$script_dir/download_update.log"

> "$log_file"

log() {
  echo "$@" | tee -a "$log_file"
}

mosdns_working_dir="/etc/mosdns"
tmp_dir="/tmp/easymosdns"
mkdir -p "$tmp_dir"

files_urls="
cloudfront_ipv4.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/cloudfront_ipv4.txt
original_domain_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/original_domain_list.txt
cachefly_ipv4.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/cachefly_ipv4.txt
private.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/private.txt
white_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/white_list.txt
block_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/block_list.txt
hosts_akamai.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/hosts_akamai.txt
hosts_fastly.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/hosts_fastly.txt
akamai_domain_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/akamai_domain_list.txt
google_cn.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/google_cn.txt
direct_domain_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/direct_domain_list.txt
redirect_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/redirect_list.txt
china_ip_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/Clash/main/rules/china_ip.txt
proxy_domain_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/proxy_domain_list.txt
gfw_ip_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/gfw_ip_list.txt
telegram-cidr.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/telegram-cidr.txt
cloudflare_ipv4.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/cloudflare_ipv4.txt
grey_list.txt https://g.blfrp.cn/https://raw.githubusercontent.com/Journalist-HK/Rules/main/grey_list.txt
"

total=$(echo "$files_urls" | grep -cve '^\s*$')
count=0
success=0
fail=0
failed_files=""

download() {
  filename="$1"
  url="$2"
  file="$tmp_dir/$filename"
  count=$((count + 1))

  if curl -fsSL "$url" -o "$file" 2>/dev/null; then
    if [ ! -s "$file" ] || [ "$(wc -l < "$file")" -lt 2 ]; then
      log "❌ 文件无效（内容异常）: $filename  [$count/$total]"
      rm -f "$file"
      fail=$((fail + 1))
      failed_files="$failed_files
$filename $url"
    else
      log "✅ 成功下载 $filename  [$count/$total]"
      success=$((success + 1))
    fi
  else
    log "❌ 下载失败（网络错误）: $filename  [$count/$total]"
    fail=$((fail + 1))
    failed_files="$failed_files
$filename $url"
  fi
}

# 第一次下载
while read -r filename url; do
  [ -z "$filename" ] && continue
  download "$filename" "$url"
done <<EOF
$files_urls
EOF

# 重试逻辑
if [ -n "$failed_files" ]; then
  log "⚠️ 发现失败文件，开始重试..."

  original_success=$success
  original_fail=$fail

  success_retry=0
  fail_retry=0
  retry_count=0
  new_failed_files=""

  retry_total=$(echo "$failed_files" | sed '/^\s*$/d' | wc -l)

  while read -r filename url; do
    [ -z "$filename" ] && continue
    retry_count=$((retry_count + 1))
    file="$tmp_dir/$filename"

    if curl -fsSL "$url" -o "$file" 2>/dev/null; then
      if [ ! -s "$file" ] || [ "$(wc -l < "$file")" -lt 2 ]; then
        log "❌ 重试失败（内容异常）: $filename  [$retry_count/$retry_total]"
        rm -f "$file"
        fail_retry=$((fail_retry + 1))
        new_failed_files="$new_failed_files
$filename $url"
      else
        log "✅ 重试成功 $filename  [$retry_count/$retry_total]"
        success_retry=$((success_retry + 1))
      fi
    else
      log "❌ 重试失败（网络或HTTP错误）: $filename  [$retry_count/$retry_total]"
      fail_retry=$((fail_retry + 1))
      new_failed_files="$new_failed_files
$filename $url"
    fi
  done <<EOF
$failed_files
EOF

  # 最终统计
  success=$((original_success + success_retry))
  fail=$((fail_retry))

  if [ -n "$new_failed_files" ]; then
    log "❌ 重试后仍有失败文件："
    echo "$new_failed_files" | sed '/^\s*$/d' | while read -r f u; do
      log "- $f"
    done
  fi
fi

# 应用结果
cp -f "$tmp_dir"/*.txt "$mosdns_working_dir/rule" 2>/dev/null
rm -rf "$tmp_dir"

log "📦 下载完成：成功 $success 失败 $fail"

/etc/init.d/mosdns reload
log "✅ 更新完成，mosdns 重载成功"
log "📄 日志已保存至：$log_file"
