#!/bin/bash
set -e

# 设置默认值（从容器环境变量中获取）
export MIXED_PORT=${MIXED_PORT:-7890}
export API_PORT=${API_PORT:-9090}
export SUBSCRIPTION_URL=${SUBSCRIPTION_URL:-}
export SECRET=${SECRET:-}
export ENABLE_SUBSCRIPTION=${ENABLE_SUBSCRIPTION:-false}
export SUBSCRIPTION_UPDATE_INTERVAL=${SUBSCRIPTION_UPDATE_INTERVAL:-24}

echo "=== 配置生成脚本启动 ==="
echo "MIXED_PORT: $MIXED_PORT"
echo "API_PORT: $API_PORT"
echo "SUBSCRIPTION_URL: $SUBSCRIPTION_URL"
echo "ENABLE_SUBSCRIPTION: $ENABLE_SUBSCRIPTION"
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

# 判断是否启用订阅功能
if [ "$ENABLE_SUBSCRIPTION" = "true" ] && [ -n "$SUBSCRIPTION_URL" ]; then
    echo "✓ 启用订阅功能"
    
    # 设置环境变量供 subscribe.sh 使用
    export sub_url="$SUBSCRIPTION_URL"
    
    echo "✓ 执行首次订阅更新..."
    if /usr/local/bin/subscribe.sh; then
        echo "✓ 首次订阅更新成功"
    else
        echo "警告: 首次订阅更新失败，但继续启动..."
    fi
    
    # 设置定时更新（如果间隔大于0）
    if [ "$SUBSCRIPTION_UPDATE_INTERVAL" -gt 0 ]; then
        echo "✓ 设置定时订阅更新，间隔: ${SUBSCRIPTION_UPDATE_INTERVAL}小时"
        
        # 创建 crontab 文件
        cat > /etc/crontabs/root << EOF
# 订阅更新任务
0 */${SUBSCRIPTION_UPDATE_INTERVAL} * * * /usr/local/bin/subscribe.sh >> /root/.config/mihomo/subscribe.log 2>&1

# 空行是必须的
EOF
        
        # 启动 crond 服务
        echo "✓ 启动 crond 服务..."
        crond -b -L /var/log/cron.log
    fi
else
    echo "ℹ️ 订阅功能未启用"
fi

# 如果提供了命令参数，则执行
if [ "$#" -gt 0 ]; then
    echo "✓ 执行命令: $@"
    exec "$@"
else
    echo "错误: 未提供启动命令"
    exit 1
fi
