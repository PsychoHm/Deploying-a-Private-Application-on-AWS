#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/user-data.log
}

# Function to install Docker
install_docker() {
    log "Starting Docker installation..."

    # Update package list
    log "Updating package list..."
    if ! sudo yum update -y; then
        log "Failed to update package list. Continuing with installation..."
    fi

    # Install Docker using Amazon Linux Extras
    log "Installing Docker using Amazon Linux Extras..."
    if sudo amazon-linux-extras install docker -y; then
        log "Docker installed successfully."
    else
        log "Failed to install Docker. Exiting."
        exit 1
    fi

    # Start Docker service
    log "Starting Docker service..."
    if sudo systemctl start docker; then
        log "Docker service started successfully."
    else
        log "Failed to start Docker service. Exiting."
        exit 1
    fi

    # Enable Docker to start on boot
    log "Enabling Docker to start on boot..."
    if sudo systemctl enable docker; then
        log "Docker enabled to start on boot."
    else
        log "Failed to enable Docker to start on boot. Continuing..."
    fi

    # Add ec2-user to the docker group
    log "Adding ec2-user to the docker group..."
    if sudo usermod -aG docker ec2-user; then
        log "ec2-user added to docker group."
    else
        log "Failed to add ec2-user to docker group. Continuing..."
    fi

    log "Docker installation completed."
}
# Main script
{
    log "Starting user data script execution"

    # Check available disk space
    log "Checking available disk space..."
    AVAILABLE_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( $(echo "$AVAILABLE_SPACE < 5" | bc -l) )); then
        log "Not enough disk space. At least 5GB required. Available: $${AVAILABLE_SPACE}GB. Exiting."
        exit 1
    fi

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        install_docker
    else
        log "Docker is already installed."
    fi

    # Create the necessary files for the visitor counter application

    # Create the app directory
    APP_DIR="/home/ec2-user/visitor_counter_app"
    mkdir -p "$APP_DIR"
    cd "$APP_DIR" || { log "Failed to change directory to $APP_DIR"; exit 1; }

    log "Creating application files..."

    # Create the Dockerfile
    cat << 'EOF' > Dockerfile
# Use the official Python image from the Docker Hub
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install the required Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
EOF

    # Create the requirements.txt file
    cat << 'EOF' > requirements.txt
Flask==2.2.2
Werkzeug==2.2.2
redis==4.0.2
EOF

    # Create the Flask application file
    cat << EOF > app.py
from flask import Flask, jsonify
import redis
import logging
import os

logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)
redis_host = os.environ.get('REDIS_HOST', 'localhost')
logging.info(f"Attempting to connect to Redis at: {redis_host}")
r = redis.Redis(host=redis_host, port=6379)

@app.route('/health', methods=['GET'])
def health_check():
    logging.info("Health check received.")
    return jsonify({"status": "healthy"}), 200

@app.route('/')
def index():
    try:
        logging.info(f"Attempting to get visitor count from Redis at {redis_host}")
        visitor_count_bytes = r.get('visitor_count')
        if visitor_count_bytes:
            visitor_count = int(visitor_count_bytes.decode('utf-8'))
        else:
            visitor_count = 0

        visitor_count += 1
        r.set('visitor_count', str(visitor_count))

        welcome_message = f"Welcome! You are visitor number {visitor_count}."
        logging.info(f"Visitor count: {visitor_count}")
        return jsonify({"message": welcome_message})
    except Exception as e:
        logging.error(f"Error: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

    log "Application files created successfully."

    # Build the visitor-counter-app Docker image
    log "Building visitor-counter-app Docker image..."
    if ! sudo docker build -t visitor-counter-app .; then
        log "Failed to build visitor-counter-app Docker image."
        exit 1
    fi

    # Remove any existing visitor-counter-app container
    VISITOR_COUNTER_CONTAINER=$(sudo docker ps -a -q --filter "name=visitor-counter-app")
    if [ -n "$VISITOR_COUNTER_CONTAINER" ]; then
        log "Removing existing visitor-counter-app container..."
        if ! sudo docker rm -f visitor-counter-app; then
            log "Failed to remove existing visitor-counter-app container."
            exit 1
        fi
    fi

    # Ensure the ElastiCache endpoint is available
    if [ -z "${elasticache_endpoint}" ]; then
        log "ElastiCache endpoint is not set. Please set the 'elasticache_endpoint' variable."
        exit 1
    fi

    # Run visitor-counter-app container with ElastiCache endpoint
    log "Running visitor-counter-app container..."
    if ! sudo docker run -d -p 5000:5000 -e REDIS_HOST="${elasticache_endpoint}" --name visitor-counter-app visitor-counter-app; then
        log "Failed to run visitor-counter-app container."
        exit 1
    fi

    # Get the EC2 instance private IP address using IMDSv2
    log "Retrieving EC2 instance private IP address..."
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    if [ $? -ne 0 ]; then
        log "Failed to retrieve IMDSv2 token"
        exit 1
    fi

    INSTANCE_PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4)
    if [ $? -ne 0 ]; then
        log "Failed to retrieve private IP address"
        exit 1
    fi

    if [ -z "$INSTANCE_PRIVATE_IP" ]; then
        log "Failed to retrieve the EC2 instance private IP address."
        exit 1
    fi

    log "Visitor counter app is running at http://$INSTANCE_PRIVATE_IP:5000"
    log "ElastiCache endpoint: ${elasticache_endpoint}"

    # Display Docker logs
    log "Docker container logs:"
    sudo docker logs visitor-counter-app

    # Create a marker file to indicate successful completion
    touch /var/lib/cloud/instance/user-data-executed

    log "User data script execution completed successfully"
} >> /var/log/user-data.log 2>&1