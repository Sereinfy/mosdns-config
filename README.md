# 基于 DNS 的内网代理分流方案



1. 基于 DNS 的流量分流，国内流量绕过 Clash 核心
2. 用 Fake-IP 模式来解决 DNS 污染的问题，但限制 Fake-IP 的范围，不需要代理的域名仍返回正常 IP
3. 兼容 BT/PT 应用，无需特殊配置也不会消耗代理流量

> https://songchenwen.com/tproxy-split-by-dns

## 流量代理分流

经过 DNS 分流以后，我们只需要一条防火墙规则，把所有目的地址是 Fake IP 的流量都转发到 Clash 核心，所有其他流量都不经转发正常通行。

OpenClash 在 Fake IP 模式下会自动帮我们添加对应的防火墙规则。但它为了防止小白误操作把其它 IP 的流量也转发到 Clash 核心了，这是没必要的，我们在自定义防火墙规则里把这条删掉就可以了。

同时由于只有 Fake IP 流量会经过代理，那么无需 DNS 解析的 IP 直连流量自然就不会经过代理了，这样就不用再担心 BT/PT 跑代理的流量了。

## 解决个别 IP 的代理问题

有的需要代理的 App 是直连 IP，不经过 DNS 域名解析的步骤的，目前我用到的只有一个，就是 telegram。好在 telegram 提供了[它所使用的 ip-cidr 列表](https://core.telegram.org/resources/cidr.txt)，我们只需要为这些 IP 单独配置防火墙规则，给它们转发到 Clash 核心。

#### OpenClash

```
#!/bin/sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

# This script is called by /etc/init.d/openclash
# Add your custom firewall rules here, they will be added after the end of the OpenClash iptables rules

LOG_OUT "Tip: Start Add Custom Firewall Rules..."

# ------------------------------------以下是自定义脚本 删除 OpenClash 对非FakeIP代理的流量转发 ---------------------------------------------------
en_mode=$(uci -q get openclash.config.en_mode)
proxy_port=$(uci -q get openclash.config.proxy_port)

if [ "$en_mode" == "fake-ip" ]; then
   LOG_OUT "update telegram ipset"
   /etc/mosdns/script/geoip2ipset.sh /etc/openclash/GeoIP.dat telegram
   sleep 1
   LOG_OUT "limit route to only fake ips with proxy port $proxy_port"
   iptables -t nat -D openclash -p tcp -j REDIRECT --to-ports $proxy_port
   iptables -t nat -A openclash -m set --match-set telegram dst -p tcp -j REDIRECT --to-ports $proxy_port
fi
# ------------------------------------自定义脚本结束---------------------------------------------------

exit 0
```

其中 `/etc/mosdns/rule/geoip2ipset.sh` 这个脚本可以根据 GeoIP 数据库来生成对应的 ipset。内容如下，这个文件放到路由器上后，记得要执行 `chmod a+x /etc/mosdns/rule/geoip2ipset.sh` 给它赋予可执行权限。



#### 遇到的

```
#!/bin/bash

geoipfile="$1"
tag="$2"
tmpdir="/tmp/v2dat"
FW4=$(command -v fw4)

cd $(cd $(dirname $BASH_SOURCE) && pwd)

mkdir -p "$tmpdir"
filename=$(basename -- "$geoipfile")
filename="${filename%.*}"
filename="$tmpdir/${filename}_$tag.txt"

if [ "$tag" == "telegram" ]; then
    wget -4 --timeout 5 -O "$filename" 'https://ghproxy.cc/https://raw.githubusercontent.com/Sereinfy/ip-preferred/main/cidr.txt'
    if [ "$?" != "0" ]; then
         /usr/bin/v2dat unpack geoip -o "$tmpdir" -f "$tag" "$geoipfile"
    fi
else
    /usr/bin/v2dat unpack geoip -o "$tmpdir" -f "$tag" "$geoipfile"
fi

if test -f "$filename"; then
    if [ -n "$FW4" ]; then
        nft add set inet fw4 "$tag" { type ipv4_addr\; flags interval\;  auto-merge\; }
        nft add set inet fw4 "${tag}6" { type ipv6_addr\; flags interval\;  auto-merge\; }
        nft flush set inet fw4 "$tag"
        nft flush set inet fw4 "${tag}6"
    fi
    ipset create "$tag" hash:net -!
    ipset create "${tag}6" hash:net family inet6 -!
    ipset flush "$tag"
    ipset flush "${tag}6"
    while read p; do
        if ! grep -q ":" <<< "$p"; then
            if [ -n "$FW4" ]; then
                nft add element inet fw4 "$tag" { "$p" }
            fi
            ipset add "$tag" "$p"
        else
            if [ -n "$FW4" ]; then
                nft add element inet fw4 "${tag}6" { "$p" }
            fi
            ipset add "${tag}6" "$p"
        fi
    done <"$filename"
else
    echo "$filename missing."
fi

rm -rf "$tmpdir"
```

#### mosdns

选自定义配置文件，取消 `DNS 转发`的勾，然后我就直接贴配置了，注意 Clash DNS 端口要改成你自己在 OpenClash 里的配置，LAN IP-CIDR 也要改成你自己的内网配置，这里 mosdns 监听了 5335 端口

```
log:
  level: info
  file: "/etc/mosdns/mosdns.log"
    
api:
  http: ":9091" # 在该地址启动 api 接口。
  
include:

plugins:
  - tag: "hosts"
    type: "hosts"
    args:
      files:
        - "/etc/mosdns/rule/hosts.txt"

  - tag: geosite_cn # 国内域名
    type: domain_set
    args:
      files:
        - "/etc/mosdns/rule/china_domain_list.txt" # https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt

  - tag: geoip_cn # 国内 IP
    type: ip_set
    args:
      files:
        - "/etc/mosdns/rule/china_ip_list.txt" # https://raw.githubusercontent.com/mayaxcn/china-ip-list/master/chnroute.txt

  - tag: cdnlist # 国内CDN
    type: domain_set
    args:
      exps:
        - "cloudflare.com"
        - "microsoft.com"
        - "playstation.com"
        - "playstation.net"
        - "redhat.com"
        - "samsung.com"
        - "ubi.com"
        - "ubisoft.com"
        - "xboxlive.com"
      files:
        - "/etc/mosdns/rule/cdn_domain_list.txt" # https://raw.githubusercontent.com/pmkol/easymosdns/rules/cdn_domain_list.txt

  - tag: gfwlist
    type: domain_set
    args:
      files:
        - "/etc/mosdns/rule/gfw.txt" # https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt
        - "/etc/mosdns/rule/proxy-list.txt" # https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt
        - "/etc/mosdns/rule/greatfire.txt" # https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt
        - "/etc/mosdns/rule/custom_list.txt" # https://raw.githubusercontent.com/Journalist-HK/Rules/master/custom_list.txt

  - tag: cloudflare_ip
    type: ip_set
    args:
      files:
        - "/etc/mosdns/rule/ip.txt" # https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt

  - tag: cloudfront_ip
    type: ip_set
    args:
      files:
        - "/etc/mosdns/rule/cloudfront.txt" # https://raw.githubusercontent.com/Journalist-HK/Rules/master/cloudfront.txt

  - tag: fastly_ip
    type: ip_set
    args:
      files:
        - "/etc/mosdns/rule/fastly.txt" # https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/fastly.txt

  - tag: "cache_0"
    type: "cache"
    args:
      size: 8192  # 默认: 1024。
      lazy_cache_ttl: 259200  # 默认: 0（禁用 lazy cache）。#建议值 86400（1天）~ 259200（3天）                     
      dump_file: /usr/share/mosdns/cache.dump
      dump_interval: 7200  # (实验性) 自动保存间隔。单位秒。默认 600。 如果距离上次 dump 有 1024 次更新，则自动保存。

  - tag: ecs_tw
    type: ecs_handler
    args:
      forward: false
      preset: 168.95.0.0
      send: false
      mask4: 16
      # mask6: 40
      
  - tag: ecs_us
    type: ecs_handler
    args:
      forward: false
      preset: 38.94.109.0
      send: false
      mask4: 24
      # mask6: 40

  - tag: "forward_local"
    type: forward
    args:
      concurrent: 2
      upstreams:
        - addr: "211.138.180.2" # 运营商 DNS，自行修改
        - addr: "211.138.180.3" # 运营商 DNS，自行修改

  - tag: "forward_alidns"
    type: forward
    args:
      concurrent: 1
      upstreams:
        - addr: "quic://223.6.6.6:853"
        - addr: "https://dns.alidns.com/dns-query"
          dial_addr: "223.5.5.5"
          enable_http3: false
          
  - tag: "forward_clash"
    type: "forward"
    args:
      concurrent: 1
      upstreams:
        - addr: "127.0.0.1:7874"

  - tag: "forward_easy"
    type: "forward"
    args:
      concurrent: 1
      upstreams:
        - addr: "https://doh.apad.pro/dns-query"
          bootstrap: "211.138.180.2"
          enable_http3: false

  - tag: "forward_remote"
    type: "forward"
    args:
      concurrent: 2 # 并发数。每次请求随机选取 concurrent 个 upstreams 发送请求。
                    # 取最快返回的应答。超过 3 最多选 3 个。默认 1。
      upstreams:
        - addr: "https://162.159.36.1/dns-query"
          enable_http3: false
          # socks5: "127.0.0.1:1080" # 目前暂不支持用户名密码认证，只支持基于 TCP 的协议
        - addr: "https://doh.opendns.com/dns-query"
          dial_addr: "146.112.41.2"
          enable_http3: false
          # 101DNS
        - addr: "tls://101.101.101.101"
          enable_pipeline: true

  - tag: remote_sequence
    type: sequence
    args:
      - exec: prefer_ipv4
      - exec: $ecs_tw
      - exec: $forward_remote
      - exec: return

  - tag: clash_sequence
    type: sequence
    args:
#      - exec: prefer_ipv4 # redir-host模式
      - exec: $forward_clash
      - exec: accept

  - tag: has_resp_sequence
    type: sequence
    args:
      - matches:
          - has_resp
        exec: accept
        
  - tag: "fallback"
    type: "fallback"
    args:
      primary: forward_easy    # forward_easy
      secondary: forward_remote  # remote
      threshold: 360           # 无响应回滚阈值。单位毫秒。默认 500 。
      always_standby: true     # 副可执行插件始终待命。
      
  - tag: fallback_sequence
    type: sequence
    args:
      - exec: prefer_ipv4
      - exec: $ecs_tw
      - exec: $fallback
      - exec: jump has_resp_sequence
      
  # IP 优选，需要定期修改，最好填写 2 - 4 个
  - tag: blackhole_cloudflare
    type: sequence
    args:
      - exec: query_summary
      - exec: black_hole 104.24.163.66 104.19.156.182 104.21.16.43
      #best_cloudflare_ip
      - exec: ttl 3600-0
      - exec: accept

  - tag: blackhole_cloudfront
    type: sequence
    args:
      - exec: query_summary
      - exec: black_hole 13.227.56.137 13.224.154.62 13.224.163.12
      #best_cloudfront_ip
      - exec: ttl 3600-0
      - exec: accept

  - tag: remote_sequence_us # 使用 US ECS 请求上游
    type: sequence
    args:
      - exec: prefer_ipv4
      - exec: $ecs_us
      - exec: $forward_remote
      - exec: jump has_resp_sequence

  - tag: fallback_sequence_us # 使用 US ECS 请求上游
    type: sequence
    args:
      - exec: prefer_ipv4
      - exec: $ecs_us
      - exec: $fallback
      - exec: jump has_resp_sequence

  - tag: change_cdn_ip_cf # https://github.com/XIU2/CloudflareSpeedTest/discussions/317
    type: sequence
    args:
      - matches:
          - qtype 1
          - has_wanted_ans
          - resp_ip $cloudflare_ip
        exec: jump blackhole_cloudflare
      - matches:
          - qtype 1
          - has_wanted_ans
          - resp_ip $cloudfront_ip
        exec: jump blackhole_cloudfront
      - exec: return

  - tag: change_CF_ip_Pending
    type: sequence
    args:
      - matches:
          - qtype 1
          - has_wanted_ans
          - resp_ip $cloudflare_ip
        exec: query_summary cloudflareCDN
      - exec: return
      
  - tag: reforward_fastly_remote # 使用 US ECS 再次查询优化 Fastly CDN 结果
    type: sequence
    args:
      - matches:
          - resp_ip $fastly_ip
        exec: jump remote_sequence_us
      - exec: return

  - tag: reforward_fastly_fallback # 使用 US ECS 再次查询优化 Fastly CDN 结果
    type: sequence
    args:
      - matches:
          - resp_ip $fastly_ip
        exec: jump fallback_sequence_us
      - exec: return

  - tag: ali_sequence
    type: sequence
    args:
      - exec: prefer_ipv4
      - exec: $forward_alidns
      - exec: jump change_cdn_ip_cf
      - exec: jump reforward_fastly_fallback
      - exec: accept # 查询失败也会停止，防止后续查询其他上游
   
  - tag: easy_sequence
    type: sequence
    args:
      - exec: $forward_easy # 未知域名优先使用分流DNS
      - matches:
          - "resp_ip $geoip_cn"
        exec: accept # 返回国内 IP 直接接受
      - exec: jump change_CF_ip_Pending
      - exec: jump reforward_fastly_fallback
      - exec: jump clash_sequence # 返回国外 IP 去clash
      
  - tag: Global_sequence
    type: sequence
    args:
      - exec: $forward_remote # 备用远程 DNS
      - matches:
          - "resp_ip $geoip_cn"
        exec: $forward_alidns # 返回国内 IP 去alidns再次解析
      - exec: jump change_CF_ip_Pending
      - exec: jump reforward_fastly_remote
      - exec: jump clash_sequence # 返回国外 IP 去clash
      
  - tag: "clash_fallback"
    type: "fallback"
    args:
      primary: easy_sequence    # 未知域名优先使用分流DNS
      secondary: Global_sequence  # 备用远程 DNS
      threshold: 360           # 无响应回滚阈值。单位毫秒。默认 500 。
      always_standby: true     # 副可执行插件始终待命。
      
  - tag: main
    type: sequence
    args:
      - matches:
          - qtype 65
        exec: reject 3 # 屏蔽 QTYPE 65

      - exec: $hosts
      - exec: jump has_resp_sequence

      - matches:
          - qname &/etc/mosdns/rule/private.txt #内网域名
        exec: reject 5 # 屏蔽内网域名

      - matches:
          - qname &/etc/mosdns/rule/white_list.txt # DDNS 和 其他白名单
        exec: $forward_local
      - exec: ttl 5-180
      - exec: jump has_resp_sequence

      - matches:
          - qname &/etc/mosdns/rule/block_list.txt # 黑名单，可添加去广告列表 
        exec: reject 5
 
      - exec: $cache_0 # 下面的请求结果均进入缓存

      - matches:
          - qname $geosite_cn $cdnlist apple.com icloud.com edgesuite.net msftconnecttest.com trafficmanager.net
        exec: jump ali_sequence
        
      - matches:
          - qname &/etc/mosdns/rule/original_domain_list.txt &/etc/mosdns/rule/grey_list.txt # 不进行 IP 替换的域名，通常是游戏等使用非常用端口的域名
        exec: jump fallback_sequence
        
      - matches:
          - qname $gfwlist &/etc/mosdns/rule/CDN_Reject.txt
        exec: jump clash_sequence # GFW 域名直接请求clash
      - exec: $clash_fallback

  - tag: udp_server
    type: udp_server
    args:
      entry: main
      listen: ":5335"

  - tag: tcp_server
    type: tcp_server
    args:
      entry: main
      listen: ":5335"
      # cert: "/etc/nginx/conf.d/_lan.crt" # 配置 cert 和 key 后会启用 TLS (DoT)。
      # key: "/etc/nginx/conf.d/_lan.key" 
      idle_timeout: 10 # 空连接超时。单位秒。默认 10。

  - tag: "http_server"
    type: "http_server"
    args:
      entries:
        - path: /dns-query     # 本路径执行
          exec: main # 可执行插件的 tag。
      src_ip_header: "X-Forwarded-For"  # 从 HTTP 头获取用户 IP。
      listen: :5443  # 监听地址。
      # cert: "/etc/nginx/conf.d/_lan.crt" # 留空 cert 和 key 后会禁用 TLS。
      # key: "/etc/nginx/conf.d/_lan.key" 
      idle_timeout: 30 # 默认 30。

```



#### 遇到的问题

- qanme写法

  ```
  准备两个txt
  只有一个里面有百度
  nslookup.exe baidu.com ok
  2个里面有百度
  Query refused
        - matches:
            - qname &/etc/mosdns/rule/baidu1.txt # 黑名单，可添加去广告列表
            - qname &/etc/mosdns/rule/baidu2.txt # 黑名单，可添加去广告列表  
          exec: reject 5
          # 确认是and关系
          
   第二种
          
        - matches:
            - qname &/etc/mosdns/rule/baidu1.txt &/etc/mosdns/rule/baidu2.txt # 只有一个里面有百度
          exec: reject 5
          Query refused
          # 确认是 or 关系
  ```
  
  