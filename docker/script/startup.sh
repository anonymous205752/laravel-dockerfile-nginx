#!/bin/bash

main() {
    setup_environment
}

# Set up the environment: run migrations, optimize, etc.
setup_environment() {
    echo "Setting up the environment..."
    grant_execute_permission
    wait_for_db
    run_migrations
    optimize_app
    # run_npm_build
    start_supervisor
}

# Ensure permissions for ./artisan
grant_execute_permission() {
    chmod a+x ./artisan
}


# Wait for the database to be ready
wait_for_db() {
    MAX_RETRIES=30
    COUNT=0
    echo "Waiting for database connection..."
    
    # Start the loop for checking the database connection
    until ./artisan migrate:status 2>&1 | grep -q -E "(Migration table not found|Migration name)" || [ $COUNT -eq $MAX_RETRIES ]; do
        sleep 1
        ((COUNT++))
        echo "Retrying... ($COUNT/$MAX_RETRIES)"
    done

    # Check if the connection was successful
    if [ $COUNT -eq $MAX_RETRIES ]; then
        echo "Database connection timed out"
        exit 1
    else
        echo "Database Connected"
    fi
}

# Run Laravel migrations
run_migrations() {
    echo "Running Laravel migrations..."
    ./artisan migrate --force
}

# Run Laravel optimize command
optimize_app() {
    echo "Optimizing Laravel application..."
    ./artisan optimize:clear
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

#Start supervisor
start_supervisor() {
    echo "Starting supervisor..."
    exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}

main "$@"