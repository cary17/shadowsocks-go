#!/bin/sh
set -e

CONFIG_FILE="/etc/ss-go/config.json"

# 获取环境变量或使用默认值
SS_NAME=${SS_NAME:-"ss-2022"}
SS_PROTOCOL=${SS_PROTOCOL:-"2022-blake3-aes-128-gcm"}
SS_PORT=${SS_PORT:-20220}
SS_TCP_PORT=${SS_TCP_PORT:-$SS_PORT}
SS_UDP_PORT=${SS_UDP_PORT:-$SS_PORT}
SS_PSK=${SS_PSK:-"qQln3GlVCZi5iJUObJVNCw=="}
SS_MTU=${SS_MTU:-1500}
SS_TCP_FASTOPEN=${SS_TCP_FASTOPEN:-true}
SS_MODE=${SS_MODE:-"server"}

# 检查必需参数
if [ -z "$SS_PSK" ]; then
    echo "Error: SS_PSK is required"
    exit 1
fi

if [ -z "$SS_PROTOCOL" ]; then
    echo "Error: SS_PROTOCOL is required"
    exit 1
fi

if [ -z "$SS_PORT" ] && [ -z "$SS_TCP_PORT" ] && [ -z "$SS_UDP_PORT" ]; then
    echo "Error: At least one port (SS_PORT, SS_TCP_PORT, or SS_UDP_PORT) is required"
    exit 1
fi

# 生成配置文件
cat > "$CONFIG_FILE" << EOF
{
    "servers": [
        {
            "name": "$SS_NAME",
            "protocol": "$SS_PROTOCOL",
            "tcpListeners": [
                {
                    "network": "tcp",
                    "address": ":$SS_TCP_PORT",
                    "fastOpen": $SS_TCP_FASTOPEN
                }
            ],
            "udpListeners": [
                {
                    "network": "udp",
                    "address": ":$SS_UDP_PORT"
                }
            ],
            "mtu": $SS_MTU,
            "psk": "$SS_PSK"
EOF

# 添加可选的 UPSK 存储路径
if [ -f "/etc/ss-go/upsks.json" ] || [ -n "$SS_UPSK_STEVE" ] || [ -n "$SS_UPSK_ALEX" ]; then
    echo "            ,\"uPSKStorePath\": \"/etc/ss-go/upsks.json\"" >> "$CONFIG_FILE"
fi

# 添加可选的额外配置
if [ -n "$SS_EXTRA_CONFIG" ]; then
    echo "            $SS_EXTRA_CONFIG" >> "$CONFIG_FILE"
fi

cat >> "$CONFIG_FILE" << EOF
        }
    ]
}
EOF

echo "Configuration file generated at $CONFIG_FILE"

# 显示生成的配置
if [ "$SS_MODE" = "server" ]; then
    echo ""
    echo "Server Configuration:"
    echo "  Name: $SS_NAME"
    echo "  Protocol: $SS_PROTOCOL"
    echo "  TCP Port: $SS_TCP_PORT (FastOpen: $SS_TCP_FASTOPEN)"
    echo "  UDP Port: $SS_UDP_PORT"
    echo "  MTU: $SS_MTU"
    echo "  PSK: $SS_PSK"
    if [ -f "/etc/ss-go/upsks.json" ]; then
        echo "  UPSK Store: /etc/ss-go/upsks.json"
    fi
fi
