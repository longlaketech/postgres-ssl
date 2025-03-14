#!/bin/bash

# exit as soon as any of these commands fail, this prevents starting a database without certificates
set -e

# Make sure there is a PGDATA variable available
if [ -z "$PGDATA" ]; then
  echo "Missing PGDATA variable"
  exit 1
fi

# Set up needed variables
SSL_DIR="/var/lib/postgresql/data/certs"
INIT_SSL_SCRIPT="/docker-entrypoint-initdb.d/init-ssl.sh"
POSTGRES_CONF_FILE="$PGDATA/postgresql.conf"

# Regenerate if the certificate is not a x509v3 certificate
if [ -f "$SSL_DIR/server.crt" ] && ! openssl x509 -noout -text -in "$SSL_DIR/server.crt" | grep -q "DNS:localhost"; then
  echo "Did not find a x509v3 certificate, regenerating certificates..."
  bash "$INIT_SSL_SCRIPT"
fi

# Regenerate if the certificate has expired or will expire
# 2592000 seconds = 30 days
if [ -f "$SSL_DIR/server.crt" ] && ! openssl x509 -checkend 2592000 -noout -in "$SSL_DIR/server.crt"; then
  echo "Certificate has or will expire soon, regenerating certificates..."
  bash "$INIT_SSL_SCRIPT"
fi

# Generate a certificate if the database was initialized but is missing a certificate
# Useful when going from the base postgres image to this ssl image
if [ -f "$POSTGRES_CONF_FILE" ] && [ ! -f "$SSL_DIR/server.crt" ]; then
  echo "Database initialized without certificate, generating certificates..."
  bash "$INIT_SSL_SCRIPT"
fi

# Apply additional PostgreSQL configuration parameters if provided via environment variables
if [ -f "$POSTGRES_CONF_FILE" ]; then
  # Configure max_wal_size if provided
  if [ ! -z "$MAX_WAL_SIZE" ]; then
    echo "Setting max_wal_size = $MAX_WAL_SIZE"
    echo "max_wal_size = '$MAX_WAL_SIZE'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure checkpoint_timeout if provided
  if [ ! -z "$CHECKPOINT_TIMEOUT" ]; then
    echo "Setting checkpoint_timeout = $CHECKPOINT_TIMEOUT"
    echo "checkpoint_timeout = '$CHECKPOINT_TIMEOUT'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure max_connections if provided
  if [ ! -z "$MAX_CONNECTIONS" ]; then
    echo "Setting max_connections = $MAX_CONNECTIONS"
    echo "max_connections = '$MAX_CONNECTIONS'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure shared_buffers if provided
  if [ ! -z "$SHARED_BUFFERS" ]; then
    echo "Setting shared_buffers = $SHARED_BUFFERS"
    echo "shared_buffers = '$SHARED_BUFFERS'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure effective_cache_size if provided
  if [ ! -z "$EFFECTIVE_CACHE_SIZE" ]; then
    echo "Setting effective_cache_size = $EFFECTIVE_CACHE_SIZE"
    echo "effective_cache_size = '$EFFECTIVE_CACHE_SIZE'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure work_mem if provided
  if [ ! -z "$WORK_MEM" ]; then
    echo "Setting work_mem = $WORK_MEM"
    echo "work_mem = '$WORK_MEM'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure idle_in_transaction_session_timeout if provided
  if [ ! -z "$IDLE_IN_TRANSACTION_SESSION_TIMEOUT" ]; then
    echo "Setting idle_in_transaction_session_timeout = $IDLE_IN_TRANSACTION_SESSION_TIMEOUT"
    echo "idle_in_transaction_session_timeout = '$IDLE_IN_TRANSACTION_SESSION_TIMEOUT'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure statement_timeout if provided
  if [ ! -z "$STATEMENT_TIMEOUT" ]; then
    echo "Setting statement_timeout = $STATEMENT_TIMEOUT"
    echo "statement_timeout = '$STATEMENT_TIMEOUT'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure autovacuum_max_workers if provided
  if [ ! -z "$AUTOVACUUM_MAX_WORKERS" ]; then
    echo "Setting autovacuum_max_workers = $AUTOVACUUM_MAX_WORKERS"
    echo "autovacuum_max_workers = '$AUTOVACUUM_MAX_WORKERS'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure autovacuum_naptime if provided
  if [ ! -z "$AUTOVACUUM_NAPTIME" ]; then
    echo "Setting autovacuum_naptime = $AUTOVACUUM_NAPTIME"
    echo "autovacuum_naptime = '$AUTOVACUUM_NAPTIME'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure maintenance_work_mem if provided
  if [ ! -z "$MAINTENANCE_WORK_MEM" ]; then
    echo "Setting maintenance_work_mem = $MAINTENANCE_WORK_MEM"
    echo "maintenance_work_mem = '$MAINTENANCE_WORK_MEM'" >> "$POSTGRES_CONF_FILE"
  fi
  
  # Configure JIT if provided
  if [ ! -z "$JIT" ]; then
    echo "Setting jit = $JIT"
    echo "jit = $JIT" >> "$POSTGRES_CONF_FILE"
  fi
fi

# unset PGHOST to force psql to use Unix socket path
# this is specific to Railway and allows
# us to use PGHOST after the init
unset PGHOST

## unset PGPORT also specific to Railway
## since postgres checks for validity of
## the value in PGPORT we unset it in case
## it ends up being empty
unset PGPORT

# Call the entrypoint script with the
# appropriate PGHOST & PGPORT and redirect
# the output to stdout if LOG_TO_STDOUT is true
if [[ "$LOG_TO_STDOUT" == "true" ]]; then
    /usr/local/bin/docker-entrypoint.sh "$@" 2>&1
else
    /usr/local/bin/docker-entrypoint.sh "$@"
fi
