#!/bin/sh

CONFIG_DIR="/root/.config/mihomo"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
TEMP_FILE="${CONFIG_DIR}/sub_temp.yaml"
LOG_FILE="${CONFIG_DIR}/log.txt"

log="[$(date +"%Y-%m-%d %H:%M:%S")] "

echo "=== 调试信息 ==="
echo "CONFIG_FILE: ${CONFIG_FILE}"
echo "TEMP_FILE: ${TEMP_FILE}"
echo "SUBSCRIPTION_URL: ${SUBSCRIPTION_URL}"

http_code=$(curl -s --max-time 60 --user-agent "clash-meta-custom" -w "%{http_code}" -o /dev/null "${SUBSCRIPTION_URL}")

if [ $? -ne 0 ] || [ "$http_code" != "200" ]; then
    log="${log}❌ 订阅下载失败，HTTP状态码: ${http_code}\n"
    printf "%b" "${log}" >> "${LOG_FILE}"
    exit 1
fi

# 下载订阅
curl -s --max-time 60 --user-agent "clash-meta-custom"  -o "${TEMP_FILE}" "${SUBSCRIPTION_URL}"

if [ $? -ne 0 ] || [ ! -s "${TEMP_FILE}" ]; then
    log="${log}❌ 订阅下载失败\n"
    printf "%b" "${log}" >> "${LOG_FILE}"
    exit 1
fi

# 检查临时文件内容
echo "=== 临时文件内容 ==="
cat "${TEMP_FILE}"
echo "=== 原配置内容 ==="
cat "${CONFIG_FILE}"

ruby << EOF
require 'yaml'
require 'net/http'
require 'uri'

begin
  # 读取原配置
  config = YAML.load_file('${CONFIG_FILE}')
  config = {} if config.nil?
  
  # 读取订阅配置
  subscription = YAML.load_file('${TEMP_FILE}')
  subscription = {} if subscription.nil?
  
  # 定义要更新的sections
  sections = ['dns', 'hosts', 'rule-providers', 'proxies', 'proxy-groups','rules']
  
  sections.each do |section|
    if subscription.key?(section)
      config[section] = subscription[section]
      puts "✅ 更新 #{section} 成功"
    else
      puts "⚠️  #{section} 未找到在订阅中"
    end
  end
  
  # 写回配置文件
  File.write('${CONFIG_FILE}', YAML.dump(config))
  puts "✅ 配置文件更新完成"
  
rescue => e
  puts "❌ 错误: #{e.message}"
  exit 1
end
EOF

# 重载配置
curl -s -X PUT "http://localhost:${API_PORT}/configs?force=true" -H "Content-Type: application/json" -d '{"path":"","payload":""}' >/dev/null
log="${log}✅ 配置重载完成\n"

printf "%b" "${log}" >> "${LOG_FILE}"