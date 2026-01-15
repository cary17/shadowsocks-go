#!/bin/sh
set -e

# 信号处理：优雅停止子进程
trap 'kill -TERM $child 2>/dev/null; wait $child 2>/dev/null' TERM INT

# 检查 shadowsocks-go 二进制是否存在
if ! command -v shadowsocks-go >/dev/null 2>&1; then
    echo "Error: shadowsocks-go is not available in this image"
    exit 1
fi

# 如果没有配置文件，生成一个
if [ ! -f /etc/ss-go/config.json ] && [ "$1" = "-c" ] && [ "$2" = "/etc/ss-go/config.json" ]; then
    echo "No configuration file found, generating from environment variables..."
    /usr/local/bin/generate-config.sh
fi

# 如果有 UPSK 环境变量，生成 upsks.json
if [ -n "$SS_UPSK_STEVE" ] || [ -n "$SS_UPSK_ALEX" ]; then
    cat > /etc/ss-go/upsks.json << EOF
{
EOF
    if [ -n "$SS_UPSK_STEVE" ]; then
        echo "    \"Steve\": \"$SS_UPSK_STEVE\"," >> /etc/ss-go/upsks.json
    fi
    if [ -n "$SS_UPSK_ALEX" ]; then
        if [ -n "$SS_UPSK_STEVE" ]; then
            echo "    \"Alex\": \"$SS_UPSK_ALEX\"" >> /etc/ss-go/upsks.json
        else
            echo "    \"Alex\": \"$SS_UPSK_ALEX\"" >> /etc/ss-go/upsks.json
        fi
    fi
    echo "}" >> /etc/ss-go/upsks.json
    echo "Generated upsks.json from environment variables"
fi

echo "Starting shadowsocks-go..."

# 在后台启动程序
exec "$@" &

child=$!
wait $child
