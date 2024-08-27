#!/bin/bash

region=$1
name_pattern=$2

ami_id=$(aws ec2 describe-images \
    --region "$region" \
    --owners amazon \
    --filters "Name=name,Values=$name_pattern" "Name=state,Values=available" "Name=architecture,Values=x86_64" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)

echo "{\"ami_id\": \"$ami_id\"}"
