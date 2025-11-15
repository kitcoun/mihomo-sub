# mihomo-sub

# 使用
· 复制.env.template文件为.evn
· 修改需要的参数

## 订阅链接转换

添加容器
```docker-compose.yml
services:
  subconverter:
    image: tindy2013/subconverter:latest
    container_name: subconverter
    restart: unless-stopped
    ports:
      - "25500:25500"
```

修改.evn订阅链接
```sh
SUBSCRIPTION_URL=http://subconverter:25500/sub?target=clash&url=你的原始订阅链接
```