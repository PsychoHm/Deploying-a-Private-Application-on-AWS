#!/bin/bash

# Generate 9 random digits
random_digits=$(printf "%09d" $((RANDOM % 1000000000)))

# Construct the bucket name
bucket_name="myappalb.logs${random_digits}"

# Output the result in JSON format
echo "{\"bucket_name\": \"$bucket_name\"}"
