#!/bin/bash

# Update and install necessary packages
yum update -y
yum install -y python3

# Create the client.py file
cat << EOF > /home/ec2-user/client.py
import requests
import time
import logging

# Set up logging
logging.basicConfig(filename='/home/ec2-user/client.log', level=logging.INFO, format='%(asctime)s - %(message)s')

# Define the URL to send GET requests to
url = "http://access.myapp.local"

# Function to send requests
def send_request():
    try:
        response = requests.get(url)
        logging.info(f"Response Status Code: {response.status_code}")
        logging.info(f"Response Content: {response.text[:100]}")
    except requests.exceptions.RequestException as e:
        logging.error(f"An error occurred: {e}")

# Run the request function once
send_request()

# Schedule the script to run every 10 seconds using cron
(crontab -l 2>/dev/null; echo "* * * * * /usr/bin/python3 /home/ec2-user/client.py") | crontab -
EOF

# Set appropriate permissions
chown ec2-user:ec2-user /home/ec2-user/client.py
chmod 644 /home/ec2-user/client.py

# Add some debugging information
echo "User data script completed" >> /var/log/user-data.log
echo "CGW Private IP: ${cgw_private_ip}" >> /var/log/user-data.log