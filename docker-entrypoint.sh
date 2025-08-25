#!/bin/bash
set -e

# Function to update Redis configuration
update_redis_conf() {
    local key="$1"
    local value="$2"
    
    if grep -q "^${key}" "$REDIS_CONF_FILE"; then
        sed -i "s|^${key}.*|${key} ${value}|" "$REDIS_CONF_FILE"
    else
        echo "${key} ${value}" >> "$REDIS_CONF_FILE"
    fi
}

# Initialize Redis configuration
if [ ! -f "$REDIS_CONF_FILE" ]; then
    cp /etc/redis/redis.conf "$REDIS_CONF_FILE"
fi

# Configure Redis based on environment variables
update_redis_conf "port" "${REDIS_PORT_NUMBER}"
update_redis_conf "dir" "${REDIS_DATA_DIR}"
update_redis_conf "logfile" "${REDIS_LOG_FILE}"
update_redis_conf "bind" "0.0.0.0"
update_redis_conf "protected-mode" "yes"

# Set Redis password if provided
if [ -n "$REDIS_PASSWORD" ]; then
    update_redis_conf "requirepass" "${REDIS_PASSWORD}"
fi

# Configure replication if in replica mode
if [ "$REDIS_REPLICATION_MODE" = "slave" ] || [ "$REDIS_REPLICATION_MODE" = "replica" ]; then
    if [ -n "$REDIS_MASTER_HOST" ]; then
        update_redis_conf "replicaof" "${REDIS_MASTER_HOST} ${REDIS_MASTER_PORT_NUMBER}"
        
        if [ -n "$REDIS_MASTER_PASSWORD" ]; then
            update_redis_conf "masterauth" "${REDIS_MASTER_PASSWORD}"
        fi
    fi
fi

# Disable specific Redis commands if specified
if [ -n "$REDIS_DISABLE_COMMANDS" ]; then
    IFS=',' read -ra COMMANDS <<< "$REDIS_DISABLE_COMMANDS"
    for cmd in "${COMMANDS[@]}"; do
        cmd=$(echo "$cmd" | xargs)  # Trim whitespace
        update_redis_conf "rename-command" "${cmd} \"\""
    done
fi

# Ensure proper permissions
chown -R redis:redis /data /config

# Drop privileges and run Redis
exec gosu redis "$@"