#!/bin/sh

# ---------------------------
# 路径与变量
# ---------------------------
CONFIG_DIR="/root/.config/mihomo"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
LOG_FILE="$CONFIG_DIR/log.txt"

output=""     # 保存生成的 config 内容
log=""        # 保存日志内容

output="${output}mixed-port: 7890\n"
output="${output}external-ui: /root/.config/mihomo/ui\n"

# ---------------------------
# 检查并安装依赖
# ---------------------------
ensure_installed() {
    pkg="$1"
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "🔧 未找到 $pkg，正在安装..."
        apk add --no-cache "$pkg"
    else
        echo "✅ $pkg 已安装"
    fi
}

# ---------------------------
# 输出日志并退出
# ---------------------------
end() {
    log="${log}\n"
    # 使用 printf %b 让 \n \t 生效
    printf "%b" "$log" >> "$LOG_FILE"
    exit 0
}

# ---------------------------
# 检查并安装依赖
# ---------------------------
ensure_installed jq
ensure_installed curl

# ---------------------------
# 订阅更新
# ---------------------------
if [ -z "$sub_url" ]; then
    echo "❌ sub_url 变量未设置"
    exit 1
fi

encoded_url=$(jq -rn --arg x "$sub_url" '$x|@uri')

log="${log}[$(date -R)] \n\t订阅文件更新...\n\t"
sub_response=$(curl -s --max-time 15 -w "%{http_code}" -o /tmp/mihomo_temp.yml "http://127.0.0.1:25500/sub?target=clash&url=$encoded_url")
sub_exit_code=$?

if [ "$sub_exit_code" -ne 0 ]; then
    log="${log}Error❌️: 网络错误，退出码: $sub_exit_code\n\t"
    end
elif [ "$sub_response" -ne 200 ]; then
    log="${log}Error❌️: 订阅文件更新失败，响应码: $sub_response\n\t"
    end
fi

# 去掉前两行写入 config
output="${output}$(awk 'NR>=3' /tmp/mihomo_temp.yml)\n"
printf "%b" "$output" > "$CONFIG_FILE"
log="${log}订阅文件更新成功 ✅\n\t"

# ---------------------------
# 配置重新加载
# ---------------------------
log="${log}配置重新加载...\n\t"
reload_response=$(curl -s --max-time 15 -w "%{http_code}" -X PUT "http://127.0.0.1:9090/configs?force=true" -H "Content-Type: application/json" -d '{"path":"","payload":""}')
reload_exit_code=$?

if [ "$reload_exit_code" -ne 0 ]; then
    log="${log}Error❌️: 网络错误，退出码: $reload_exit_code\n\t"
    end
elif [ "$reload_response" -ne 204 ]; then
    log="${log}Error❌️: 配置重新加载失败，响应码: $reload_response\n\t"
    end
fi

log="${log}配置重新加载完成 ✅\n\t"
end
