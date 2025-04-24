# Step 1: Use the neolink v0.6.2 image as the base for copying artifacts
FROM quantumentangledandy/neolink:v0.6.2 AS base

# Step 2: Create the release container
FROM debian:bookworm-slim

LABEL description="An image for the neolink program which is a reolink camera to rtsp translator."
LABEL maintainer="waveguide <voltage.solutions@outlook.com>"

# Step 3: Set environment variables
ENV NEO_LINK_MODE="rtsp" NEO_LINK_PORT=8554

# Step 4: Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        openssl \
        dnsutils \
        iputils-ping \
        ca-certificates \
        libgstrtspserver-1.0-0 \
        libgstreamer1.0-0 \
        gstreamer1.0-tools \
        gstreamer1.0-x \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-libav \
        cron && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Step 5: Copy the build artifacts from the base image
COPY --from=base /usr/local/bin/neolink /usr/local/bin/neolink

# Step 6: Ensure the entrypoint script exists and is executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Step 7: Add the cron job
RUN echo "*/5 * * * * /usr/local/bin/run_neolink.sh >> /var/log/neolink.log 2>&1" | crontab -

# Step 8: Create the log directory
RUN mkdir -p /var/log && touch /var/log/neolink.log

# Step 9: Expose the port
EXPOSE ${NEO_LINK_PORT}

# Step 10: Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]