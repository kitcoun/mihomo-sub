# mihomo-sub
来源于[MetaCubeX](https://github.com/MetaCubeX)

## 使用
- 复制`.env.template`文件为`.evn`
- 修改需要的参数
- 默认部署两个核心，不需要可以在`docker-compose.yml`删除
- 更改.env、config.yaml.template等，需要重新编译镜像
```yml
docker compose build

docker compose up -d 
```

## 服务默认端口
- 代理 `mixed` 端口: `7771`
- Web 面板: `http://localhost:8011/ui`
- Mihomo 代理核心 API: `http://localhost:9191`
- 订阅链接转换: `http://localhost:25500`

## 订阅链接转换
修改`evn`,你的订阅链接需要编码。[参考](https://github.com/tindy2013/subconverter/blob/master/README-cn.md)
```sh
SUBSCRIPTION_URL=http://subconverter:25500/sub?target=clash&url=你的订阅链接
```
修改docker-compose.yml的订阅链接转换服务
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

## 已采用mihomo自带订阅
因为官方订阅会覆盖配置文件的所有设置,所以放在`./providers/subscription.yaml`
然后有会脚本去更新订阅到实际的配置文件
```yml
# `config.yaml.template`文件
proxy-providers:
  app:
    type: http
    url: "${SUBSCRIPTION_URL}"
    interval: ${SUBSCRIPTION_UPDATE_INTERVAL}
    path: ./providers/subscription.yaml
    health-check:
      enable: true
      interval: 3000
      url: http://www.gstatic.com/generate_204
```

## 手动更新订阅到实际的配置文件
```sh
# 方式1：使用已设置的环境变量
docker exec mihomo-node-1 /usr/local/bin/subscribe.sh

# 方式3：带详细输出
docker exec -it mihomo-node-1 /usr/local/bin/subscribe.sh
```
## docker中使用
在其他容器使用
```yml
services:
    .....
    networks:
      - proxy_shared_network
    .....

networks:
  proxy_shared_network:
    external: true
```
在上面的容器中测试

```sh
curl -x http://localhost:7771 https://www.google.com
curl -x http://mihomo-node-1:7890 https://www.google.com
```
