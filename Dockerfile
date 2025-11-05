FROM metacubex/mihomo:v1.19.15

RUN apk add jq
RUN apk add curl

ADD https://github.com/MetaCubeX/metacubexd/releases/download/v1.195.0/compressed-dist.tgz /root/metacubexd.tgz
RUN mkdir -p /root/.config/mihomo/ui && tar -xzf /root/metacubexd.tgz -C /root/.config/mihomo/ui
RUN rm -rf /root/metacubexd.tgz

ADD https://github.com/tindy2013/subconverter/releases/download/v0.9.0/subconverter_linux64.tar.gz /root/subconverter_linux64.tar.gz
RUN tar -xzf /root/subconverter_linux64.tar.gz -C /
RUN rm -rf /root/subconverter_linux64.tar.gz

# 15min    daily    hourly   monthly  weekly
ADD sub.sh /etc/periodic/hourly/sub.sh
RUN chmod +x /etc/periodic/hourly/sub.sh

RUN echo 'mixed-port: 7890' >> /root/.config/mihomo/config.yaml && \
    echo 'external-ui: /root/.config/mihomo/ui' >> /root/.config/mihomo/config.yaml && \
    echo 'allow-lan: true' >> /root/.config/mihomo/config.yaml && \
    echo 'external-controller: :9090' >> /root/.config/mihomo/config.yaml

EXPOSE 7890
EXPOSE 9090

# 创建启动脚本
RUN echo '#!/bin/sh' > /mihomo_init.sh && \
    echo '/mihomo &' >> /mihomo_init.sh && \
    echo '/subconverter/subconverter &' >> /mihomo_init.sh && \
    echo 'sleep 5' >> /mihomo_init.sh && \
    echo '/etc/periodic/hourly/sub.sh' >> /mihomo_init.sh && \
    echo 'exec crond -f -d 8' >> /mihomo_init.sh && \
    chmod +x /mihomo_init.sh

ENTRYPOINT ["/mihomo_init.sh"]