#!/bin/bash

main() {
    setup_environment
}

setup_environment() {
    echo "Setting up the environment..."
    grant_execute_permission
    wait_for_db
    clear_and_optimize_app
    run_migrations
    # run_npm_build  # Uncomment if needed
    start_supervisor
}

grant_execute_permission() {
    chmod a+x ./artisan
}

wait_for_db() {
    MAX_RETRIES=30
    COUNT=0
    DB_HOST=${DB_HOST:-db}
    DB_PORT=${DB_PORT:-5432}

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

run_migrations() {
    echo "Running Laravel migrations..."
    ./artisan migrate --force
}

clear_and_optimize_app() {
    echo "Clearing and optimizing Laravel caches..."
    ./artisan config:clear
    ./artisan cache:clear
    ./artisan route:clear
    ./artisan view:clear
    ./artisan config:cache
    ./artisan optimize
}

start_supervisor() {
    echo "Starting Supervisor..."
    exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}

main "$@"
