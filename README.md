# mihomo-sub

## 使用
- 复制.env.template文件为.evn
- 修改需要的参数

## 服务默认端口
- 代理 `mixed` 端口: `7890`
- Web 面板: `http://localhost:8011/ui`
- Mihomo 代理核心 API: `http://localhost:9090`
- 订阅链接转换: `http://localhost:25500`

## 订阅链接转换
修改evn,你的订阅链接需要编码。[参考](https://github.com/tindy2013/subconverter/blob/master/README-cn.md)
```sh
SUBSCRIPTION_URL=http://subconverter:25500/sub?target=clash&url=你的订阅链接
```
订阅链接转换服务
```yml
subconverter:
    image: tindy2013/subconverter:latest
    container_name: subconverter
    restart: unless-stopped
    networks:
        - proxy_shared_network
    environment:
        - "TZ=Asia/Shanghai"
    ports:
        - "25500:25500"
```

## 官方订阅
添加到config.yaml.template文件。官方订阅会覆盖配置文件
```yml
proxy-providers:
  app:
    type: http
    url: "${SUBSCRIPTION_URL}"
    interval: 3600
    # path: ./providers/subscription.yaml
    path: ./config.yaml
    health-check:
      enable: true
      interval: 3000
      url: http://www.gstatic.com/generate_204
```

## 手动执行订阅
```sh
# 方式1：使用已设置的环境变量
docker exec mihomo-node-1 /usr/local/bin/subscribe.sh

# 方式2：临时指定订阅URL
docker exec -e SUBSCRIPTION_URL="新的订阅链接" mihomo-node-1 /usr/local/bin/subscribe.sh

# 方式3：带详细输出
docker exec -it mihomo-node-1 /usr/local/bin/subscribe.sh
```