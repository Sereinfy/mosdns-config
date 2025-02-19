  ```
如果不能运行，把update.sh运行之后 rule 文件里的 1kb 的文件打开看一下，有可能是文件获取失败了，手动更新下
  ```
# 基于 DNS 的内网代理分流方案
  ```
 mosdns
    ├── 国内
    │   ├── 正常IP 
    │
    └── 国外
        ├──Openclash── FakeIP
        │或
        └── 无污染真实IP
  ```
## 核心思路

### 1. **域名解析策略**
- **国内域名**：使用运营商 DNS 解析。
- **国外域名**：使用国外知名公共 DNS 解析。

### 2. **域名分流规则**
- **国内列表**：
  - 文件：`wall_list.txt`（需手动创建）。
  - 作用：手动指定某些域名走国外（或通过 Clash 转发）。
- **国外列表**：
  - 文件：`akamai_domain_list.txt`。
  - 作用：与国内列表合并，指定某些国外域名走直连。

### 3. **分流结构示例**
- `wall_list.txt` → 走国外。
- `google_cn` → 走国外（或直连，慎用）。
- `geosite_cn` → 走直连。
- `akamai_domain_list.txt` → 走直连。
- `proxy_domain_list.txt` → 走国外。

### 4. **配置文件**
- `update.sh`：包含所有相关文件的更新

---

## 操作指南

### 1. **刷新缓存**
修改配置后，执行以下命令刷新缓存：
```bash
curl -s 127.0.0.1:9091/plugins/缓存的文件名/flush || exit 1
  ```

### 2. ** 通过 Socks5 代理优化境外 DNS 解析**

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
### 3. ** 代码来源**
  https://github.com/Journalist-HK/mosdns-config
