  ```
如果不能运行，把update.sh运行之后 rule 文件里的 1kb 的文件打开看一下，有可能是文件获取失败了，手动更新下
  ```
# 基于 DNS 的内网代理分流方案

## 主要思路

1. **国内域名解析**：使用运营商 DNS 进行解析。
2. **国内列表**：在国内域名之前有一个 `wall_list.txt`（需手动创建），用于手动将特定域名提前走国外，或者发送给 Clash。
3. **国外列表**：在国外域名之前有一个 `akamai_domain_list.txt`，这个列表与国内列表放在一起，走直连。
4. **结构示例**：
   - `wall_list.txt` → 走国外
   - `google_cn` → 走国外（也可以走直连 [慎用]）
   - `geosite_cn` → 走直连
   - `akamai_domain_list.txt` → 走直连
   - `proxy_domain_list.txt` → 走国外
5. **国外域名解析**：使用国外知名公共 DNS 进行解析。
   
`update.sh` 文件中包含所有的文件。
## 修改配置后刷新缓存
  ```
curl -s 127.0.0.1:9091/plugins/cache_0/flush || exit 1
  ```

## 通过 socks5 代理来提高境外 DNS 的联通性

  ```
  - tag: "forward_remote"
    type: "forward"
    args:
      concurrent: 1
      upstreams:
        - addr: "https://162.159.36.1/dns-query"
          enable_http3: false
          socks5: "127.0.0.1:1080" # 目前暂不支持用户名密码认证，只支持基于 TCP 的协议
        - addr: "https://162.159.46.1/dns-query"
          enable_http3: false
  ```
## 代码修改来源
  https://github.com/Journalist-HK/mosdns-config
