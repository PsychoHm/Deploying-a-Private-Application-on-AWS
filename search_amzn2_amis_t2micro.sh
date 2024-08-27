#!/bin/bash

# Function to check if t2.micro is available in a specific region
check_t2_micro() {
    local region=$1
    echo "Checking availability of t2.micro in $region:"
    if aws ec2 describe-instance-type-offerings \
        --region $region \
        --location-type availability-zone \
        --filters "Name=instance-type,Values=t2.micro" \
        --query 'length(InstanceTypeOfferings)' \
        --output text | grep -q '^0$'; then
        echo "t2.micro is NOT available in $region"
    else
        echo "t2.micro is available in $region"
    fi
    echo
}

# Function to search for AMIs in a specific region
search_amis() {
    local region=$1
    echo "Searching for Amazon Linux 2 AMIs (kernel 5.10) in $region..."
    aws ec2 describe-images \
        --region $region \
        --owners amazon \
        --filters "Name=name,Values=amzn2-ami-kernel-5.10-hvm-2.0*" "Name=state,Values=available" "Name=architecture,Values=x86_64" \
        --query 'Images[*].[ImageId,Name,CreationDate]' \
        --output table
    echo
}

# Main script
regions=("us-east-2" "us-east-1")

# First, check t2.micro availability for both regions
for region in "${regions[@]}"; do
    check_t2_micro $region
done

# Then, search for AMIs in both regions
for region in "${regions[@]}"; do
    search_amis $region
done
