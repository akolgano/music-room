FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r flutter && useradd -r -g flutter flutter -m

RUN mkdir -p /home/flutter && chown -R flutter:flutter /home/flutter

# Use a specific Flutter version for consistency
RUN git clone -b stable https://github.com/flutter/flutter.git /flutter \
    && chown -R flutter:flutter /flutter

RUN mkdir -p /app && chown -R flutter:flutter /app

USER flutter

ENV PATH="/flutter/bin:${PATH}"
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web
# Pre-download Flutter dependencies
RUN flutter precache --web

WORKDIR /app
COPY --chown=flutter:flutter pubspec.* ./
RUN flutter pub get
COPY --chown=flutter:flutter . .
# Build with verbose output and skip tree shaking for better compatibility
RUN flutter build web --release --verbose --no-tree-shake-icons

FROM nginx:alpine

RUN addgroup -g 1001 -S nginx-app && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx-app -g nginx-app nginx-app

COPY --from=builder /app/build/web /usr/share/nginx/html

RUN mkdir -p /tmp/nginx/client_temp /tmp/nginx/proxy_temp \
    /tmp/nginx/fastcgi_temp /tmp/nginx/uwsgi_temp \
    /tmp/nginx/scgi_temp /var/log/nginx \
    && chown -R nginx-app:nginx-app /tmp/nginx /var/log/nginx \
    && chown -R nginx-app:nginx-app /usr/share/nginx/html

RUN echo 'pid /tmp/nginx.pid; \
error_log /var/log/nginx/error.log; \
events { \
    worker_connections 1024; \
} \
http { \
    include /etc/nginx/mime.types; \
    default_type application/octet-stream; \
    access_log /var/log/nginx/access.log; \
    sendfile on; \
    keepalive_timeout 65; \
    client_body_temp_path /tmp/nginx/client_temp; \
    proxy_temp_path /tmp/nginx/proxy_temp; \
    fastcgi_temp_path /tmp/nginx/fastcgi_temp; \
    uwsgi_temp_path /tmp/nginx/uwsgi_temp; \
    scgi_temp_path /tmp/nginx/scgi_temp; \
    server { \
        listen 8080; \
        server_name localhost; \
        location / { \
            root /usr/share/nginx/html; \
            index index.html index.htm; \
            try_files $uri $uri/ /index.html; \
        } \
    } \
}' > /etc/nginx/nginx.conf

RUN rm -f /etc/nginx/conf.d/*.conf

USER nginx-app

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
