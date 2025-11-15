#!/bin/sh

# ---------------------------
# 路径与变量
# ---------------------------
CONFIG_DIR="/root/.config/mihomo"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
LOG_FILE="${CONFIG_DIR}/log.txt"

output=""     # 保存生成的 config 内容
log=""        # 保存日志内容
success_flag=true  # 整体执行状态标志

output="${output}mixed-port: 7890\n"
output="${output}external-ui: /root/.config/mihomo/ui\n"

# ---------------------------
# 检查并安装依赖
# ---------------------------
ensure_installed() {
    pkg="$1"
    if ! command -v "${pkg}" >/dev/null 2>&1; then
        echo "🔧 未找到 ${pkg}，正在安装..."
        if ! apk add --no-cache "${pkg}" >/dev/null 2>&1; then
            echo "❌ 安装 ${pkg} 失败"
            return 1
        fi
    else
        echo "✅ ${pkg} 已安装"
    fi
    return 0
}

# ---------------------------
# 输出日志并继续执行
# ---------------------------
log_and_continue() {
    log="${log}\n"
    # 使用 printf %b 让 \n \t 生效
    printf "%b" "${log}" >> "${LOG_FILE}"
    log=""  # 清空日志缓冲区
}

# ---------------------------
# 记录错误并设置标志
# ---------------------------
record_error() {
    local error_msg="$1"
    log="${log}${error_msg}\n\t"
    success_flag=false
    log_and_continue
}

# ---------------------------
# 主程序开始
# ---------------------------

# ---------------------------
# 检查并安装依赖
# ---------------------------
log="${log}[$(date +"%Y-%m-%d %H:%M:%S %z")] 开始检查依赖...\n\t"

if ! ensure_installed jq; then
    record_error "❌ jq 安装失败，但将继续执行"
fi

if ! ensure_installed curl; then
    record_error "❌ curl 安装失败，但将继续执行"
fi

log="${log}依赖检查完成\n\t"
log_and_continue

# ---------------------------
# 订阅更新
# ---------------------------
log="${log}[$(date +"%Y-%m-%d %H:%M:%S %z")] 开始订阅更新...\n\t"

if [ -z "${sub_url}" ]; then
    record_error "❌ sub_url 变量未设置"
else
    encoded_url=$(jq -rn --arg x "${sub_url}" '$x|@uri' 2>/dev/null)
    if [ -z "${encoded_url}" ]; then
        record_error "❌ URL 编码失败"
    else
        log="${log}encoded_url: ${encoded_url}\n\tsub_url: ${sub_url}\n\t"
        
        # sub_response=$(curl -s --max-time 15 -w "%{http_code}" -o /tmp/mihomo_temp.yml "http://127.0.0.1:25500/sub?target=clash&url=$encoded_url")
        sub_response=$(curl -s --user-agent "clash-verge/v99.4.2" --max-time 15 -o /tmp/mihomo_temp.yml "$sub_url")
        sub_exit_code=$?

        if [ "${sub_exit_code}" -ne 0 ]; then
            record_error "❌ 网络错误，退出码: ${sub_exit_code}"
        else
            # 检查临时文件是否存在且有效
            if [ -f /tmp/mihomo_temp.yml ] && [ -s /tmp/mihomo_temp.yml ]; then
                # 去掉前两行写入 config
                output="${output}$(awk 'NR>=3' /tmp/mihomo_temp.yml)\n"
                if printf "%b" "${output}" > "${CONFIG_FILE}"; then
                    log="${log}✅ 订阅文件更新成功\n\t"
                else
                    record_error "❌ 配置文件写入失败"
                fi
            else
                record_error "❌ 临时文件不存在或为空"
            fi
        fi
    fi
fi

log_and_continue

# ---------------------------
# 配置重新加载
# ---------------------------
log="${log}[$(date +"%Y-%m-%d %H:%M:%S %z")] 开始配置重新加载...\n\t"

reload_response=$(curl -s --max-time 15 -w "%{http_code}" -X PUT "http://127.0.0.1:9090/configs?force=true" -H "Content-Type: application/json" -d '{"path":"","payload":""}')
reload_exit_code=$?

if [ "${reload_exit_code}" -ne 0 ]; then
    record_error "❌ 重新加载网络错误，退出码: ${reload_exit_code}"
elif [ "${reload_response}" -ne 204 ]; then
    record_error "❌ 配置重新加载失败，响应码: ${reload_response}"
else
    log="${log}✅ 配置重新加载完成\n\t"
fi

log_and_continue

# ---------------------------
# 最终状态汇总
# ---------------------------
if [ "$success_flag" = "true" ]; then
    log="${log}[$(date +"%Y-%m-%d %H:%M:%S %z")] ✅ 所有操作执行成功\n\t"
else
    log="${log}[$(date +"%Y-%m-%d %H:%M:%S %z")] ⚠️ 部分操作失败，但已继续执行完成\n\t"
fi

log_and_continue

exit 0