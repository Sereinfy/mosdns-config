  ```
如果不能运行，把update.sh运行之后 rule 文件里的 1kb 的文件打开看一下，有可能是文件获取失败了，手动更新下
  ```
# MosDNS 智能分流方案

## 文件准备
```bash
mosdns/
├── rule/                  # 规则目录
│   ├── wall_list.txt      # 手动创建 - 走国外代理的域名列表
├── output/                # 输出目录
│   ├── dns_hijack.txt     # 手动创建 - 被污染域名列表
├── update.sh              # 自动更新脚本
└── config.yaml            # 主配置文件
  ```
对于新发现被污染的域名，先添加到 dns_hijack.txt，若仍无法解决再添加到 wall_list.txt
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
