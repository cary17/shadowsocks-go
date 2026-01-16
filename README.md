# Shadowsocks-go Docker Image

基于官方 [shadowsocks-go](https://github.com/database64128/shadowsocks-go) 构建的 Docker 镜像。

## 特性

- 🚀 自动检测 CPU 架构并下载对应版本（x86-64-v2/v3, arm64）
- 🐧 基础镜像：Debian stable-slim
- 🔄 每小时自动检测新版本并构建
- 📦 最小化镜像体积，多阶段构建
- 🔧 支持环境变量配置和挂载配置文件
- 🛡️ 以非 root 用户运行
- ⚡ 优雅停止子进程

## 镜像标签

### Debian 基础镜像
- `latest` / `latest-debian` - Debian stable-slim 最新版
- `v1.14.0` / `v1.14.0-debian` - 指定版本

## 快速开始

### 使用环境变量（服务端）

```bash
docker run -d \
  --name shadowsocks-go \
  -p 20220:20220/tcp \
  -p 20220:20220/udp \
  -e SS_SERVER_NAME="ss-2022" \
  -e SS_PROTOCOL="2022-blake3-aes-128-gcm" \
  -e SS_PSK="qQln3GlVCZi5iJUObJVNCw==" \
  -e SS_TCP_ADDRESS=":20220" \
  -e SS_UDP_ADDRESS=":20220" \
  ghcr.io/your-username/shadowsocks-go:latest
```

### 使用配置文件

```bash
# 准备配置文件目录
mkdir -p ./ss-config

# 创建配置文件（服务端或客户端）
cat > ./ss-config/config.json << 'EOF'
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
            "psk": "qQln3GlVCZi5iJUObJVNCw=="
        }
    ]
}
EOF

# 运行容器
docker run -d \
  --name shadowsocks-go \
  -p 20220:20220/tcp \
  -p 20220:20220/udp \
  -v $(pwd)/ss-config:/etc/ss-go \
  ghcr.io/your-username/shadowsocks-go:latest
```

## 环境变量

### 必填项

| 变量 | 说明 | 示例 |
|------|------|------|
| `SS_SERVER_NAME` | 服务器名称 | `ss-2022` |
| `SS_PROTOCOL` | 协议类型 | `2022-blake3-aes-128-gcm` |
| `SS_PSK` | 预共享密钥 | `qQln3GlVCZi5iJUObJVNCw==` |

### 可选项

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `SS_TCP_ADDRESS` | TCP 监听地址 | `:20220` |
| `SS_UDP_ADDRESS` | UDP 监听地址 | `:20220` |
| `SS_MTU` | MTU 大小 | `1500` |
| `SS_TCP_FASTOPEN` | TCP Fast Open | `true` |
| `SS_UPSK_USERS` | 多用户配置 | - |

### 多用户配置示例

```bash
docker run -d \
  --name shadowsocks-go \
  -p 20220:20220/tcp \
  -p 20220:20220/udp \
  -e SS_SERVER_NAME="ss-2022" \
  -e SS_PROTOCOL="2022-blake3-aes-128-gcm" \
  -e SS_PSK="qQln3GlVCZi5iJUObJVNCw==" \
  -e SS_UPSK_USERS="Steve:oE/s2z9Q8EWORAB8B3UCxw==,Alex:hWXLOSW/r/LtNKynrA3S8Q==" \
  ghcr.io/your-username/shadowsocks-go:latest
```

这将自动生成 `/etc/ss-go/upsks.json` 文件。

## Docker Compose 示例

```yaml
version: '3.8'

services:
  shadowsocks-go:
    image: ghcr.io/your-username/shadowsocks-go:latest
    container_name: shadowsocks-go
    restart: unless-stopped
    ports:
      - "20220:20220/tcp"
      - "20220:20220/udp"
    environment:
      - SS_SERVER_NAME=ss-2022
      - SS_PROTOCOL=2022-blake3-aes-128-gcm
      - SS_PSK=qQln3GlVCZi5iJUObJVNCw==
      - SS_TCP_ADDRESS=:20220
      - SS_UDP_ADDRESS=:20220
      - SS_MTU=1500
      - SS_TCP_FASTOPEN=true
    # 或者使用挂载配置文件
    # volumes:
    #   - ./ss-config:/etc/ss-go
```

## 镜像体积对比

| 基础镜像 | 大小 (约) |
|----------|-----------|
| Debian stable-slim | ~80MB |
| Alpine latest | ~20MB |

Alpine 镜像更小，Debian 镜像兼容性更好，根据需求选择。

## 手动构建

### Debian 镜像

```bash
docker build \
  -f Dockerfile.debian \
  --build-arg SS_GO_VERSION=v1.14.0 \
  -t shadowsocks-go:v1.14.0-debian .
```

### Alpine 镜像

```bash
docker build \
  -f Dockerfile.alpine \
  --build-arg SS_GO_VERSION=v1.14.0 \
  -t shadowsocks-go:v1.14.0-alpine .
```

### 多架构构建

```bash
# Debian
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile.debian \
  --build-arg SS_GO_VERSION=v1.14.0 \
  -t shadowsocks-go:v1.14.0-debian \
  --push .

# Alpine
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile.alpine \
  --build-arg SS_GO_VERSION=v1.14.0 \
  -t shadowsocks-go:v1.14.0-alpine \
  --push .
```

## GitHub Actions 工作流

### 自动构建

镜像会在以下情况自动构建：

1. 每小时检测官方新版本发布
2. 新版本号大于 GHCR 中现有版本时自动触发构建
3. 同时构建 Debian 和 Alpine 两种镜像
4. 同时推送到 GHCR 和 Docker Hub

### 手动触发构建

在 GitHub Actions 中手动运行 `Build Docker Images` 工作流，可指定：

- `ss_go_version`: 版本号（如 `v1.14.0`，留空则使用最新版）
- `force_build`: 强制构建（即使版本已存在）

## 配置 Secrets

在 GitHub 仓库设置中添加以下 Secrets：

- `DOCKERHUB_USERNAME`: Docker Hub 用户名
- `DOCKERHUB_TOKEN`: Docker Hub 访问令牌或密码

GHCR 无需额外配置，使用 `GITHUB_TOKEN` 自动认证。

## 客户端配置示例

```json
{
    "clients": [
        {
            "name": "my-client",
            "protocol": "2022-blake3-aes-128-gcm",
            "address": "server.example.com:20220",
            "psk": "qQln3GlVCZi5iJUObJVNCw=="
        }
    ],
    "tcpListeners": [
        {
            "network": "tcp",
            "address": "127.0.0.1:1080"
        }
    ],
    "udpListeners": [
        {
            "network": "udp",
            "address": "127.0.0.1:1080"
        }
    ]
}
```

客户端配置必须通过挂载配置文件方式使用。

## 优化特性

### 体积最小化
- ✅ 多阶段构建，仅复制必要文件
- ✅ 清理所有临时文件和缓存
- ✅ 使用 `--no-install-recommends` 安装依赖
- ✅ Alpine 基础镜像仅 ~20MB

### 安全性
- ✅ 以非 root 用户 `shadowsocks` 运行
- ✅ 配置文件权限设置为 600
- ✅ 最小化攻击面

### 可靠性
- ✅ 信号处理优雅停止子进程
- ✅ 5 次重试机制，间隔 10 秒
- ✅ 完整的错误处理

## 注意事项

1. **CPU 架构检测**: 对于 x86-64，会自动检测 CPU 是否支持 AVX2/BMI2 指令集来选择 v3 或 v2 版本
2. **配置优先级**: 如果挂载了配置文件，环境变量配置将被忽略
3. **多用户配置**: 格式为 `用户名1:PSK1,用户名2:PSK2`
4. **端口映射**: TCP 和 UDP 端口可以不一致，根据实际配置映射
5. **优雅停止**: 容器停止时会发送 TERM 信号给子进程，等待其优雅退出

## 许可证

本项目遵循 MIT 许可证，shadowsocks-go 项目请参考其[官方仓库](https://github.com/database64128/shadowsocks-go)。
