#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /sismologia_api/tmp/pids/server.pid

# Check if the database exists, if not, create it
bundle exec rake db:create || true

# Run database migrations
bundle exec rake db:migrate

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
