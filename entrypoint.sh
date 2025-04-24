#!/bin/bash

# Enable debugging for troubleshooting (remove `set -x` in production)
set -e

# Function to handle cleanup and termination
cleanup() {
    echo "$(date): Stopping neolink..."
    if [[ -n "$NEOLINK_PID" ]] && kill -0 "$NEOLINK_PID" 2>/dev/null; then
        kill "$NEOLINK_PID"
        wait "$NEOLINK_PID"
        echo "$(date): neolink stopped."
    else
        echo "$(date): No active neolink process to stop."
    fi
    exit 0
}

# Trap signals to cleanup on container shutdown
trap cleanup SIGTERM SIGINT

# Read total run interval from environment or default to 300 seconds (5 minutes)
TOTAL_INTERVAL=${NEO_LINK_INTERVAL:-300}
ACTIVE_RUNTIME=20  # Time neolink runs
SLEEP_TIME=$((TOTAL_INTERVAL - ACTIVE_RUNTIME))

echo "$(date): Entrypoint script started. Running in a loop every $TOTAL_INTERVAL seconds."

# Main loop
while true; do
    echo "$(date): Starting neolink with mode: $NEO_LINK_MODE"

    # Start neolink in the background
    /usr/local/bin/neolink "$NEO_LINK_MODE" --config /etc/neolink.toml &
    NEOLINK_PID=$!

    echo "$(date): neolink started with PID $NEOLINK_PID"

    # Run for the active runtime
    sleep $ACTIVE_RUNTIME

    # Stop the process
    echo "$(date): Stopping neolink after $ACTIVE_RUNTIME seconds."
    if kill "$NEOLINK_PID" 2>/dev/null; then
        wait "$NEOLINK_PID" || true
        echo "$(date): neolink process $NEOLINK_PID stopped."
    else
        echo "$(date): Failed to stop neolink process $NEOLINK_PID."
    fi

    # Convert sleep time into minutes and seconds
    MINUTES=$((SLEEP_TIME / 60))
    SECONDS=$((SLEEP_TIME % 60))

    if [[ $MINUTES -gt 0 ]]; then
        echo "$(date): Sleeping for $MINUTES minutes and $SECONDS seconds before the next run."
    else
        echo "$(date): Sleeping for $SECONDS seconds before the next run."
    fi

    sleep $SLEEP_TIME
done