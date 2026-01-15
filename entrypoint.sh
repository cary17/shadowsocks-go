#!/bin/sh

set -e

CONFIG_FILE="/etc/ss-go/config.json"
UPSK_FILE="/etc/ss-go/upsks.json"

# 信号处理：优雅停止子进程
trap 'kill -TERM $child 2>/dev/null; wait $child 2>/dev/null' TERM INT

# 如果配置文件不存在且设置了环境变量，则生成配置
if [ ! -f "$CONFIG_FILE" ] && [ -n "$SS_SERVER_NAME" ]; then
    echo "Generating server configuration..."
    
    # 必填项检查
    if [ -z "$SS_PROTOCOL" ]; then
        echo "Error: SS_PROTOCOL is required"
        exit 1
    fi
    if [ -z "$SS_PSK" ]; then
        echo "Error: SS_PSK is required"
        exit 1
    fi
    if [ -z "$SS_TCP_ADDRESS" ]; then
        SS_TCP_ADDRESS=":20220"
    fi
    if [ -z "$SS_UDP_ADDRESS" ]; then
        SS_UDP_ADDRESS=":20220"
    fi
    
    # 设置默认值
    SS_SERVER_NAME="${SS_SERVER_NAME:-ss-2022}"
    SS_MTU="${SS_MTU:-1500}"
    SS_TCP_FASTOPEN="${SS_TCP_FASTOPEN:-true}"
    
    # 构建基础配置
    cat > "$CONFIG_FILE" << EOF
{
    "servers": [
        {
            "name": "$SS_SERVER_NAME",
            "protocol": "$SS_PROTOCOL",
            "tcpListeners": [
                {
                    "network": "tcp",
                    "address": "$SS_TCP_ADDRESS",
                    "fastOpen": $SS_TCP_FASTOPEN
                }
            ],
            "udpListeners": [
                {
                    "network": "udp",
                    "address": "$SS_UDP_ADDRESS"
                }
            ],
            "mtu": $SS_MTU,
            "psk": "$SS_PSK"
EOF

    # 处理 uPSK 配置
    if [ -n "$SS_UPSK_USERS" ]; then
        echo "            ,\"uPSKStorePath\": \"$UPSK_FILE\"" >> "$CONFIG_FILE"
        
        # 生成 upsks.json
        echo "{" > "$UPSK_FILE"
        
        # 解析用户配置 格式: user1:psk1,user2:psk2
        FIRST=1
        IFS=','
        for ENTRY in $SS_UPSK_USERS; do
            USER=$(echo "$ENTRY" | cut -d':' -f1)
            PSK=$(echo "$ENTRY" | cut -d':' -f2)
            
            if [ $FIRST -eq 1 ]; then
                FIRST=0
            else
                echo "," >> "$UPSK_FILE"
            fi
            
            echo -n "    \"$USER\": \"$PSK\"" >> "$UPSK_FILE"
        done
        unset IFS
        
        echo "" >> "$UPSK_FILE"
        echo "}" >> "$UPSK_FILE"
        
        chmod 600 "$UPSK_FILE"
    else
        echo "" >> "$CONFIG_FILE"
    fi
    
    # 完成配置文件
    cat >> "$CONFIG_FILE" << EOF
        }
    ]
}
EOF

    chmod 600 "$CONFIG_FILE"
    echo "Configuration generated at $CONFIG_FILE"
    
    if [ -f "$UPSK_FILE" ]; then
        echo "uPSK configuration generated at $UPSK_FILE"
    fi
fi

# 启动 shadowsocks-go 并在后台运行
/usr/local/bin/shadowsocks-go "$@" &
child=$!

# 等待子进程
wait $child
