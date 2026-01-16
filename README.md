# Shadowsocks-go Docker

基于官方 [shadowsocks-go](https://github.com/database64128/shadowsocks-go) 的 Docker 镜像，支持多架构自动构建。

## 支持的架构

- `linux/amd64/v2` - x86-64-v2（支持 AVX 指令集）
- `linux/amd64/v3` - x86-64-v3（支持 AVX2 指令集）
- `linux/arm64` - ARM64 架构

## 快速开始

### 使用环境变量配置
```bash
docker run -d \
  --name shadowsocks-go \
  -p 20220:20220/tcp \
  -p 20220:20220/udp \
  -e SS_SERVER_NAME=ss-2022 \
  -e SS_PROTOCOL=2022-blake3-aes-128-gcm \
  -e SS_PSK=your_base64_psk_here \
  ghcr.io/cary17/shadowsocks-go:latest
```

### 使用配置文件
```bash
docker run -d \
  --name shadowsocks-go \
  -p 20220:20220/tcp \
  -p 20220:20220/udp \
  -v /path/to/config:/etc/ss-go \
  ghcr.io/cary17/shadowsocks-go:latest
```

### 使用 Docker Compose

下载 `docker-compose.yml` 文件并修改配置，然后运行：
```bash
docker-compose up -d
```

## 环境变量说明

| 变量名 | 必填 | 默认值 | 说明 |
|--------|------|--------|------|
| `SS_SERVER_NAME` | 是 | - | 服务器名称 |
| `SS_PROTOCOL` | 是 | - | 协议类型，如 `2022-blake3-aes-128-gcm` |
| `SS_PSK` | 是 | - | Base64 编码的预共享密钥 |
| `SS_TCP_ADDRESS` | 否 | `:20220` | TCP 监听地址 |
| `SS_UDP_ADDRESS` | 否 | `:20220` | UDP 监听地址 |
| `SS_MTU` | 否 | `1500` | MTU 大小 |
| `SS_TCP_FASTOPEN` | 否 | `true` | 是否启用 TCP Fast Open |
| `SS_UPSK_USERS` | 否 | - | 多用户配置，格式：`user1:psk1,user2:psk2` |

## 生成 PSK

使用 `openssl` 生成随机密钥：
# 2022-blake3-aes-128-gcm
```bash
openssl rand -base64 16
```
# 2022-blake3-aes-256-gcm
```bash
openssl rand -base64 32
```

## 支持的协议

- `2022-blake3-aes-128-gcm`
- `2022-blake3-aes-256-gcm`
- `2022-blake3-chacha20-poly1305`

## 多用户配置示例

使用环境变量：
```bash
docker run -d \
  --name shadowsocks-go \
  -p 20220:20220/tcp \
  -p 20220:20220/udp \
  -e SS_SERVER_NAME=ss-2022 \
  -e SS_PROTOCOL=2022-blake3-aes-128-gcm \
  -e SS_PSK=main_psk_here \
  -e SS_UPSK_USERS="Alice:$(openssl rand -base64 16),Bob:$(openssl rand -base64 16)" \
  ghcr.io/cary17/shadowsocks-go:latest
```

## 自动构建

本项目使用 GitHub Actions 自动构建：

- **定时构建**：每小时检查一次新版本
- **手动触发**：可在 Actions 页面手动触发构建
- **版本检测**：自动检测并构建最新版本，避免重复构建

### 手动触发构建

1. 进入仓库的 Actions 页面
2. 选择 "Build Docker Images" workflow
3. 点击 "Run workflow"
4. 可选择指定版本或使用最新版本
5. 可选择强制构建已存在的版本

## 镜像仓库

- **GitHub Container Registry**: `ghcr.io/cary17/shadowsocks-go:latest`
- **Docker Hub**（可选）: `cary17/shadowsocks-go:latest`

## 配置文件格式

如果使用挂载配置文件方式，请参考 [shadowsocks-go 官方文档](https://github.com/database64128/shadowsocks-go)。

示例 `config.json`：
```json
{
    "servers": [
        {
            "name": "ss-2022",
            "protocol": "2022-blake3-aes-128-gcm",
            "tcpListeners": [
                {
                    "network": "tcp",
                    "address": ":20220",
                    "fastOpen": true
                }
            ],
            "udpListeners": [
                {
                    "network": "udp",
                    "address": ":20220"
                }
            ],
            "mtu": 1500,
            "psk": "your_base64_psk_here"
        }
    ]
}
```
