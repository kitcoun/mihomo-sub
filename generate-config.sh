#!/bin/bash
set -e

# 设置默认值（从容器环境变量中获取）
export MIXED_PORT=${MIXED_PORT:-7890}
export API_PORT=${API_PORT:-9090}
export SUBSCRIPTION_URL=${SUBSCRIPTION_URL:-}
export SECRET=${SECRET:-}
export SUBSCRIPTION_UPDATE_INTERVAL=${SUBSCRIPTION_UPDATE_INTERVAL:-3600}

echo "=== 配置生成脚本启动 ==="
echo "MIXED_PORT: $MIXED_PORT"
echo "API_PORT: $API_PORT"
echo "SUBSCRIPTION_URL: $SUBSCRIPTION_URL"
echo "SUBSCRIPTION_UPDATE_INTERVAL: $SUBSCRIPTION_UPDATE_INTERVAL"

# 验证订阅 URL 是否设置
if [ -z "$SUBSCRIPTION_URL" ]; then
    echo "警告: SUBSCRIPTION_URL 未设置！"
fi

# 使用 envsubst 替换模板中的变量
if [ ! -f /tmp/config.yaml.template ]; then
    echo "错误: 配置模板文件不存在: /tmp/config.yaml.template"
    exit 1
fi

envsubst < /tmp/config.yaml.template > /root/.config/mihomo/config.yaml

echo "✓ 配置文件已生成: /root/.config/mihomo/config.yaml"

# 创建 crontab 文件
UPDATE_CRON_MINUTES=$((SUBSCRIPTION_UPDATE_INTERVAL / 60 + 1))
echo "更新间隔: $UPDATE_CRON_MINUTES 分钟"
cat > /etc/crontabs/root << EOF
# 自动更新订阅模板
*/${UPDATE_CRON_MINUTES} * * * * /usr/local/bin/subscribe.sh >> /root/.config/mihomo/subscribe.log 2>&1

# 空行是必须的
EOF

# 启动 crond 服务
echo "✓ 启动 crond 服务..."
crond -b -L /var/log/cron.log

(
    sleep 60    
    echo "✓ 首次启动订阅配置更新..."
    source /usr/local/bin/subscribe.sh
) &

# 如果提供了命令参数，则执行
if [ "$#" -gt 0 ]; then
    echo "✓ 执行命令: $@"
    exec "$@"
else
    echo "错误: 未提供启动命令"
    exit 1
fi
