# Stage 1: 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

# 安装依赖
COPY package*.json ./
# 如果构建慢，可以保留这个国内源配置
RUN npm config set registry https://registry.npmmirror.com/
RUN npm install

# 复制源码并构建
COPY . .
RUN npm run build

# Stage 2: 运行阶段 (Nginx)
FROM nginx:alpine

# 将构建好的文件复制到 Nginx 目录
COPY --from=builder /app/dist /usr/share/nginx/html

# 这里不需要 SSL 配置了，直接用默认的 80 端口即可
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
