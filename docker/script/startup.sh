#!/bin/bash

main() {
    setup_environment
}

# Set up the environment: run migrations, optimize, etc.
setup_environment() {
    echo "Setting up the environment..."
    grant_execute_permission
    wait_for_db
    clear_and_optimize_app
    run_migrations
    # run_npm_build
    start_supervisor
}

# Ensure permissions for ./artisan
grant_execute_permission() {
    chmod a+x ./artisan
}

# Wait for the database to be ready using netcat (nc)
wait_for_db() {
    MAX_RETRIES=30
    COUNT=0
    echo "Waiting for database connection at $DB_HOST:$DB_PORT..."

    until nc -z "$DB_HOST" "$DB_PORT"; do
        sleep 3
        ((COUNT++))
        echo "Retrying... ($COUNT/$MAX_RETRIES)"
        if [ $COUNT -ge $MAX_RETRIES ]; then
            echo "❌ Database connection timed out"
            exit 1
        fi
    done

    echo "✅ Database Connected"
}

# Run Laravel migrations
run_migrations() {
    echo "Running Laravel migrations..."
    ./artisan migrate --force
}

# Clear and optimize Laravel cache
clear_and_optimize_app() {
    echo "Clearing and optimizing Laravel caches..."
    ./artisan config:clear
    ./artisan cache:clear
    ./artisan route:clear
    ./artisan view:clear
    ./artisan config:cache
    ./artisan optimize
}

# Build web apps (Uncomment in setup_environment if needed for web apps)
run_npm_build() {
    if [ -f "package.json" ]; then
        if [ ! -d "node_modules" ]; then
            echo "Running NPM clean install"
            npm ci
        fi
        echo "Running NPM build"
        npm run build
    else
        echo "No package.json found, skipping NPM build"
    fi
}

# Start Supervisor
start_supervisor() {
    echo "Starting Supervisor..."
    exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}

main "$@"
