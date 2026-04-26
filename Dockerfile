FROM php:8.2-fpm-alpine

# 1. 시스템 패키지 및 PHP 확장 의존성 설치
RUN apk add --no-cache \
    caddy supervisor bash shadow git curl \
    freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev \
    icu-dev libxml2-dev libzip-dev oniguruma-dev curl-dev

# 2. PHP 확장 모듈 설치
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) \
    gd mysqli pdo_mysql opcache exif intl zip bcmath

# 3. rhymix 사용자 생성 (기본 UID/GID 1000)
RUN groupadd -g 1000 rhymix && \
    useradd -u 1000 -g rhymix -m -s /bin/bash rhymix

# 4. PHP-FPM 실행 유저 변경
RUN sed -i "s/user = www-data/user = rhymix/g" /usr/local/etc/php-fpm.d/www.conf && \
    sed -i "s/group = www-data/group = rhymix/g" /usr/local/etc/php-fpm.d/www.conf

# 5. [수정됨] php.ini 설정 (session.auto_start 및 라이믹스 권장값)
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    { \
        echo "session.auto_start = Off"; \
        echo "date.timezone = Asia/Seoul"; \
        echo "memory_limit = 512M"; \
        echo "post_max_size = 128M"; \
        echo "upload_max_filesize = 100M"; \
        echo "opcache.enable=1"; \
        echo "opcache.memory_consumption=128"; \
        echo "opcache.interned_strings_buffer=8"; \
        echo "opcache.max_accelerated_files=10000"; \
        echo "opcache.revalidate_freq=2"; \
    } >> /usr/local/etc/php/php.ini

# 6. 설정 파일 및 환영 파일 복사
COPY Caddyfile /etc/caddy/Caddyfile
COPY welcome.php /usr/local/bin/welcome.php

# 7. Supervisor 설정 생성
RUN printf "[supervisord]\n\
nodaemon=true\n\
user=root\n\
logfile=/var/log/supervisord.log\n\
pidfile=/run/supervisord.pid\n\
\n\
[program:php-fpm]\n\
command=php-fpm\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
\n\
[program:caddy]\n\
command=caddy run --config /etc/caddy/Caddyfile\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n" > /etc/supervisord.conf

# 8. Entrypoint 스크립트 작성
RUN printf "#!/bin/bash\n\
USER_ID=\${PUID:-1000}\n\
GROUP_ID=\${PGID:-1000}\n\
echo \"--- [INFO] 권한 설정 중: UID \$USER_ID / GID \$GROUP_ID ---\"\n\
groupmod -g \$GROUP_ID rhymix 2>/dev/null || true\n\
usermod  -u \$USER_ID -g \$GROUP_ID rhymix 2>/dev/null || true\n\
if [ ! -f /var/www/html/index.php ]; then\n\
    echo \"--- [INFO] 첫 방문 환영 파일을 복사합니다. ---\"\n\
    cp /usr/local/bin/welcome.php /var/www/html/index.php\n\
fi\n\
chown -R rhymix:rhymix /var/www/html\n\
exec /usr/bin/supervisord -c /etc/supervisord.conf" > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]