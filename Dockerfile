# Stage 1: Build the project
FROM node:18-alpine AS builder

WORKDIR /app

# 复制 package.json 并安装依赖
# 注意：如果国内网络不好，可能需要配置 npm 镜像，这里预留了配置
COPY package*.json ./
RUN npm config set registry https://registry.npmmirror.com/
RUN npm install

# 复制源代码并构建
COPY . .
# 假设构建命令是 build，如果是 vite 项目通常生成在 dist 目录
RUN npm run build

# Stage 2: Serve with Nginx (with SSL for Camera access)
FROM nginx:alpine

# 安装 OpenSSL 以生成自签名证书
RUN apk add --no-cache openssl

# 创建 SSL 证书存放目录
RUN mkdir -p /etc/nginx/ssl

# 生成自签名证书 (有效期 3650 天)
# 这一步是手机能访问摄像头的关键
RUN openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/self.key \
    -out /etc/nginx/ssl/self.crt \
    -subj "/C=CN/ST=State/L=City/O=MyRouter/CN=localhost"

# 移除默认配置
RUN rm /etc/nginx/conf.d/default.conf

# 写入支持 HTTPS 的 Nginx 配置
# 注意：我们将把构建好的文件 (dist) 复制到 /usr/share/nginx/html
COPY --from=builder /app/dist /usr/share/nginx/html

# 创建自定义 Nginx 配置文件
RUN echo 'server { \
    listen 80; \
    listen 443 ssl; \
    server_name localhost; \
    \
    ssl_certificate /etc/nginx/ssl/self.crt; \
    ssl_certificate_key /etc/nginx/ssl/self.key; \
    \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
