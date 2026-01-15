#!/bin/sh
set -e

# 信号处理：优雅停止子进程
trap 'kill -TERM $child 2>/dev/null; wait $child 2>/dev/null' TERM INT

# 检查 shadowsocks-go 二进制是否存在
if ! command -v shadowsocks-go >/dev/null 2>&1; then
    echo "Error: shadowsocks-go is not available in this image"
    exit 1
fi

# 生成 upsks.json 如果存在 UPSK 环境变量
generate_upsks_json() {
    local first=true
    
    # 收集所有 SS_UPSK_* 环境变量
    for var in $(env | grep '^SS_UPSK_' | sort); do
        username=$(echo "$var" | cut -d= -f1 | sed 's/^SS_UPSK_//')
        psk=$(echo "$var" | cut -d= -f2)
        
        if [ "$first" = "true" ]; then
            echo "{" > /etc/ss-go/upsks.json
            echo "    \"$username\": \"$psk\"" >> /etc/ss-go/upsks.json
            first=false
        else
            echo "    ,\"$username\": \"$psk\"" >> /etc/ss-go/upsks.json
        fi
    done
    
    if [ "$first" = "false" ]; then
        echo "}" >> /etc/ss-go/upsks.json
        echo "Generated upsks.json from environment variables"
        
        # 显示生成的用户
        echo "UPSK Users:"
        for var in $(env | grep '^SS_UPSK_' | sort); do
            username=$(echo "$var" | cut -d= -f1 | sed 's/^SS_UPSK_//')
            echo "  - $username"
        done
    fi
}

# 如果没有配置文件，生成一个
if [ ! -f /etc/ss-go/config.json ] && [ "$1" = "-c" ] && [ "$2" = "/etc/ss-go/config.json" ]; then
    echo "No configuration file found, generating from environment variables..."
    /usr/local/bin/generate-config.sh
fi

# 生成 upsks.json
generate_upsks_json

echo "Starting shadowsocks-go..."

# 在后台启动程序
exec "$@" &

child=$!
wait $child