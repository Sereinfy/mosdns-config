



# MosDNS 智能分流方案

国内返回正常IP,国外返回无污染IP或fakeip 

支持akamai cname cloudflare CDN cloudfront CDN替换IP

一般情况下只有cloudflare需求比较大，且CloudflareST自带测速地址和ip段。

如果需要cloudfront的测速地址和ip段，可在CloudflareST讨论区找到

至于akamai 我的使用场景是一些使用了akamai CDN的动漫网站，但是本身速度也不差，加速意义不大。

由于我做了全自动的测速加替换脚本，所以akamai我默认是测速并替换的。

> 注意这一项使用black_hole参数，使用优选ip修改掉dns应答的默认ip 也就是默认线路，ip通过测速软件CloudflareST获取

| 网址    | IP地址    |备注|
| ----- | ------- |------- |
| a.com | 1.1.1.1|默认返回的CDN|
| a.com | 2.2.2.2 |被black_hole修改后的CDN|

> 等于强制使用2.2.2.2（优选ip）来访问 a.com

以及通过hosts_akamai，hosts_fastly替换网站线路

cloudfront因地区限速，需要测试后才能确定有没有替换的意义。我这里已经恢复正常测速。

> 如果被限速（测速结果0-5m/s以下）正常应该是10m/s以上

```
  - tag: blackhole_cloudfront_ipv4
    type: sequence
    args:
    #  - exec: black_hole 13.32.60.227 13.226.58.100 13.226.62.159  #注释这一行即可
      - exec: query_summary cloudfront_best
      - exec: ttl 3600-0
      - exec: accept
```






## 文件准备
```bash
mosdns/
├── rule/                  # 规则目录
│   ├── wall_list.txt      # 手动创建 - 走国外代理的域名列表，手动更新
│   ├── dns_hijack.txt     # 手动创建 - 被污染域名列表，从日志中提取，手动更新，也可以脚本自动更新
├── output/                # 输出目录
├── script/                # 脚本目录
│   ├──script/update.sh    # 规则自动更新脚本
└── config.yaml            # 主配置文件
  ```

## 分流结构

  ```
mosdns
  ├── 国内流量
  │   ├── 正常IP → 直连
  │
  └── 国外流量
      ├── Openclash → FakeIP
      │或
      └── 无污染真实IP
  ```
google_cn 相关域名建议走国外，如需直连请谨慎评估

### crontab 定时任务

  ```
0 4 * * * /etc/mosdns/update.sh
  ```

### 代码来源

  https://github.com/Journalist-HK/mosdns-config
