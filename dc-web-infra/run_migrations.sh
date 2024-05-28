#!/bin/sh

export POSTGRES_USER=${MIGRATION_USER}
export POSTGRES_PASSWORD=${MIGRATION_PASSWORD}

until pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready"

echo "Running migrations..."
/app/bin/llm_chat eval "LlmChat.Release.migrate"
