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

## 遇到的问题

  ``` 1. qanme 写法


准备两个 txt 文件：
- 只有一个文件里面有百度：
  nslookup.exe baidu.com ok

- 两个文件里面都有百度：
  Query refused
    - matches:
        - qname & /etc/mosdns/rule/baidu1.txt # 黑名单，可添加去广告列表
        - qname & /etc/mosdns/rule/baidu2.txt # 黑名单，可添加去广告列表  
      exec: reject 5
      # 确认是 AND 关系

### 2. 第二种情况


- matches:
    - qname & /etc/mosdns/rule/baidu1.txt & /etc/mosdns/rule/baidu2.txt # 只有一个文件里面有百度
  exec: reject 5
  Query refused
  # 确认是 OR 关系
  ```
## 代码修改来源
  https://github.com/Journalist-HK/mosdns-config
