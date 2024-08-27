#!/bin/bash

# Update and install necessary packages
yum update -y
yum install -y python3 python3-pip

# Install the requests library
pip3 install requests

# Create the client.py file
cat << EOF > /home/ec2-user/client.py
#!/usr/bin/env python3
import requests
import time

url = "http://access.myapp.internal"

while True:
    try:
        response = requests.get(url)
        print(f"Status Code: {response.status_code}")
        print(f"Content: {response.text[:100]}")
    except Exception as e:
        print(f"Error: {e}")
    
    time.sleep(5)
EOF

# Set appropriate permissions
chown ec2-user:ec2-user /home/ec2-user/client.py
chmod 755 /home/ec2-user/client.py

# Add some debugging information
echo "Setup script completed" >> /var/log/setup.log
echo "To run the script, type: python3 /home/ec2-user/client.py"
