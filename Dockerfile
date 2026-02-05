# Stage 1: Build nginx from source with WebDAV module
FROM alpine:latest as builder

# Set nginx version and module versions
ENV NGINX_VERSION=1.28.2
ENV NGINX_DAV_EXT_VER=4.0.1
ENV HEADERS_MORE_VER=0.39

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    automake \
    libxml2-dev

# Download and extract nginx source
WORKDIR /src
RUN curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz && \
    mkdir -p /usr/src && \
    tar -zxC /usr/src -f nginx.tar.gz && \
    rm nginx.tar.gz

# Download and extract nginx-dav-ext-module source
RUN curl -fSL https://github.com/mid1221213/nginx-dav-ext-module/archive/v${NGINX_DAV_EXT_VER}.tar.gz -o dav-ext.tar.gz && \
    mkdir -p /usr/src/nginx-dav-ext-module && \
    tar -zxC /usr/src -f dav-ext.tar.gz && \
    rm dav-ext.tar.gz

# Download and extract headers-more-nginx-module source
RUN curl -fSL https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VER}.tar.gz -o headers-more.tar.gz && \
    mkdir -p /usr/src/headers-more-nginx-module && \
    tar -zxC /usr/src -f headers-more.tar.gz && \
    rm headers-more.tar.gz

# Configure and build nginx with WebDAV modules
WORKDIR /usr/src/nginx-$NGINX_VERSION
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-pcre \
    --with-pcre-jit \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --add-module=/usr/src/nginx-dav-ext-module-${NGINX_DAV_EXT_VER} \
    --add-module=/usr/src/headers-more-nginx-module-${HEADERS_MORE_VER} && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

# Stage 2: Create the final image
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    openssl \
    pcre \
    apache2-utils \
    bash \
    libgcc \
    tzdata \
    libxml2 \
    libxslt

# Create nginx user/group
RUN addgroup -S nginx && \
    adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

# Copy nginx from builder stage
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

# Create required directories
RUN mkdir -p /var/cache/nginx/client_temp && \
    mkdir -p /var/cache/nginx/proxy_temp && \
    mkdir -p /var/cache/nginx/fastcgi_temp && \
    mkdir -p /var/cache/nginx/uwsgi_temp && \
    mkdir -p /var/cache/nginx/scgi_temp && \
    mkdir -p /data && \
    mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/cache/nginx

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /entrypoint.sh

# Set environment variables with defaults
ENV CLIENT_MAX_BODY_SIZE=0

# Expose port 80
EXPOSE 80

# Set the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["nginx", "-g", "daemon off;"]
