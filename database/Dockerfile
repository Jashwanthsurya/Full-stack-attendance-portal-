# Database Dockerfile for JSON data persistence
FROM alpine:latest

# Install basic tools
RUN apk add --no-cache jq

# Create data directory
RUN mkdir -p /data

# Copy initial data files
COPY data/ /data/

# Set proper permissions
RUN chmod 755 /data
RUN chmod 644 /data/*.json

# Create volume for data persistence
VOLUME ["/data"]

# Keep container running
CMD ["tail", "-f", "/dev/null"]