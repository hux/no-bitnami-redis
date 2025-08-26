FROM debian:bullseye-slim

# Install Redis and required packages
RUN apt-get update && apt-get install -y \
    redis-server \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Create redis user and group (skip if already exists)
RUN groupadd -r -g 1001 redis 2>/dev/null || true \
    && useradd -r -g redis -u 1001 redis 2>/dev/null || true

# Create necessary directories
RUN mkdir -p /data /config \
    && chown -R redis:redis /data /config

# Copy configuration files
COPY redis.conf /config/redis.conf
COPY docker-entrypoint.sh /usr/local/bin/

# Make entrypoint executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment variables
ENV REDIS_PORT_NUMBER=6379 \
    REDIS_DATA_DIR=/data \
    REDIS_CONF_FILE=/config/redis.conf \
    REDIS_LOG_FILE=/dev/stdout \
    REDIS_DISABLE_COMMANDS="" \
    REDIS_PASSWORD="" \
    REDIS_MASTER_HOST="" \
    REDIS_MASTER_PORT_NUMBER=6379 \
    REDIS_MASTER_PASSWORD="" \
    REDIS_REPLICATION_MODE="" \
    REDIS_REPLICA_IP="" \
    REDIS_REPLICA_PORT=""

VOLUME ["/data"]

EXPOSE 6379

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["redis-server", "/config/redis.conf"]