#!/bin/bash
set -e

# 设置默认值（从容器环境变量中获取）
export MIXED_PORT=${MIXED_PORT:-7890}
export API_PORT=${API_PORT:-9090}
export SUBSCRIPTION_URL=${SUBSCRIPTION_URL:-}
export SECRET=${SECRET:-}

echo "=== 配置生成脚本启动 ==="
echo "MIXED_PORT: $MIXED_PORT"
echo "API_PORT: $API_PORT"
echo "SUBSCRIPTION_URL: $SUBSCRIPTION_URL"

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

# 如果提供了命令参数，则执行
if [ "$#" -gt 0 ]; then
    echo "✓ 执行命令: $@"
    exec "$@"
else
    echo "错误: 未提供启动命令"
    exit 1
fi
