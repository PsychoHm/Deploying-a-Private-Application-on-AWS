# Deploying a Private Application on AWS

## Project Overview

This project demonstrates the deployment of a private application on the AWS Cloud, accessible from an on-premises network through an AWS Site-to-Site VPN connection. The on-premises network is simulated using a Virtual Private Cloud (VPC) called the Client VPC, while the application resides in a separate VPC called the Application VPC. The two VPCs are deployed in different AWS regions (us-east-2 and us-east-1, respectively) and connected via a Site-to-Site VPN.

## Project Architecture 

![Screenshot 2024-08-23 at 12 51 18](https://github.com/user-attachments/assets/55857821-fc96-4581-8895-3182d1757fff)


## Infrastructure Components

### 1. Client VPC:

* Consists of two subnets: a private subnet hosting a client EC2 instance, and a public subnet hosting a Customer Gateway (CGW) instance.
* The client EC2 instance connects to the application using the DNS name access.myapp.internal through a Python script that sends GET requests every 5 seconds.
* The CGW instance serves as the gateway for the Client VPC, handling VPN termination with OpenSwan and DNS functionalities with dnsmasq.

### 2. Application VPC:

* Includes an Amazon Route 53 (R53) inbound resolver endpoint to allow inbound traffic from the DNS server located in the on-premises network.
* An Application Load Balancer (ALB) forwards traffic to two EC2 instances running the web application, with access logs enabled.
* A Private Hosted Zone in Route 53 with an alias record matching access.myapp.internal to the ALB's FQDN.
* The web application is a Flask application with the following functionality:
    * Connects to an ElastiCache Redis instance using the REDIS_HOST environment variable.
    * Defines two routes: /health (returns a JSON response with the status "healthy") and / (the root route for visitor counting).
    * When the root route is accessed, the application retrieves the current visitor count from Redis, increments it, stores the new count, generates a welcome message, and returns a JSON response with the message.
    * Logs any exceptions and returns a JSON response with the error message and a 500 HTTP status code.
    * Runs on 0.0.0.0 (all available interfaces) and listens on port 5000.

## Implementation

The project is implemented using Terraform, an Infrastructure as Code (IaC) tool that enables easy deployment and management of AWS resources. The Terraform configuration is organized into modules for better code organization and reusability. The main components of the project structure include:

* `main.tf`: The main Terraform file that orchestrates the deployment of the entire infrastructure across the two AWS regions.
* `modules/`: A directory containing various Terraform modules responsible for creating and configuring specific resources, such as VPCs, EC2 instances, ALB, ElastiCache, Route53, and more.
* `user_data_scripts/`: Directory containing user data scripts (`app_user_data.sh` and `client_user_data.sh`) executed on the respective EC2 instances during launch for tasks like installing Docker, building the Flask application Docker image, running the application container, and configuring the client instance for DNS resolution.
* `variables.tf`: File defining the input variables required for the Terraform configuration, allowing customization of the deployment based on specific requirements.

## Deployment Process

The main Terraform file (`main.tf`) orchestrates the deployment of the entire infrastructure by following these steps:

1. **Provider Configuration**:
   - Configure AWS providers for the us-east-1 (Application VPC) and us-east-2 (Client VPC) regions.

2. **VPC Setup**:
   - Create the Application VPC in us-east-1 using the `app_vpc` module.
   - Create the Client VPC in us-east-2 using the `client_vpc` module.
   - Both VPCs are set up with public and private subnets, route tables, internet gateways, and NAT gateways.

3. **Security Groups**:
   - Use the `security_groups` module to create and configure security groups for various components in both VPCs.

4. **VPN and VGW Setup**:
   - Create an Elastic IP (EIP) for the Customer Gateway (CGW).
   - Use the `vpn` module to set up a Site-to-Site VPN connection between the Application VPC and the Client VPC.

5. **ElastiCache Setup**:
   - Deploy an ElastiCache Redis cluster in the Application VPC using the `elasticache` module.

6. **IAM and S3 Setup**:
   - Use the `iam` module to create necessary IAM roles and policies.
   - Set up an S3 bucket for ALB access logs using the `s3` module.

7. **EC2 Instances for the Application**:
   - Launch two EC2 instances (`ec2_app1` and `ec2_app2`) in the Application VPC's private subnets using the `ec2-app` module.
   - Configure these instances with the appropriate user data, security groups, and IAM roles.

8. **Application Load Balancer (ALB)**:
   - Create an ALB in the Application VPC using the `alb` module.
   - Configure the ALB to distribute traffic between the two application instances.
   - Set up target group attachments for the application instances.

9. **Customer Gateway (CGW) Setup**:
   - Launch an EC2 instance to act as the CGW in the Client VPC's public subnet using the `ec2-client` module.
   - Associate the previously created EIP with the CGW instance.

10. **DNS and Route53 Setup**:
    - Configure DHCP options for the Client VPC.
    - Use the `route53` module to create a private hosted zone for the "myapp.internal" domain.
    - Set up a Route53 record pointing to the ALB.
    - Deploy Route53 Resolver endpoints using the `resolver` module for cross-VPC DNS resolution.

11. **Client EC2 Instance**:
    - Launch a client EC2 instance in the Client VPC's private subnet using the `ec2-client` module.
    - Configure this instance with appropriate user data for accessing the application.

12. **Additional Networking Configuration**:
    - Set up routes in the Client VPC to direct traffic to the Application VPC through the CGW.
    - Configure the CGW instance using the `ssm` module for VPN and routing setup.

13. **Final Configurations**:
    - Set up the necessary routes and DHCP options for proper communication between VPCs.

# Deployment Guide

This document provides a comprehensive step-by-step guide for deploying the project from the GitHub repository.

## Prerequisites

- **Terraform**: Ensure that Terraform is installed on your system.
- **AWS CLI**: Configure the AWS CLI with the appropriate credentials to manage your AWS resources.

## Deployment Steps

### Step 1: Repository Cloning

Clone the GitHub repository to your local environment:

```bash
git clone https://github.com/PsychoHm/Deploying-a-Private-Application-on-AWS
cd Deploying-a-Private-Application-on-AWS/
```

### Step 2: AMI Configuration / S3 bucket name suggestion

Ensure the use of valid AMI IDs for the specified regions. Execute the following commands in the root directory:
 
```bash
chmod +x scripts/suggest_bucket_name.sh
chmod +x scripts/get_latest_ami.sh
```

### Step 3: S3 Module Configuration

Navigate to the `./modules/s3/main.tf` file and make the following updates:

- Replace `elb-account-id` with the ID of the AWS account for Elastic Load Balancing in your region. For more details, refer to the [AWS documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html).
- Replace `123456789` with your actual AWS Account ID.

```hcl
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::127311923021:root" # Replace with ELB account ID
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${var.bucket_name}/AWSLogs/123456789/*" # Replace with your AWS Account ID
      }
    ]
  })
}
```

### Step 4: Initialize and Validate Terraform Configuration

Run the following command in the root directory to initialize and validate your Terraform configuration:

```bash
terraform init && terraform fmt -recursive && terraform validate
```

![terrform_init](https://github.com/user-attachments/assets/64dcf2e2-fa0b-43aa-94e3-391b9e739ee2)


Ensure that you see the message: **"Success! The configuration is valid."**

### Step 5: Apply Terraform Configuration

Execute the following command to apply the Terraform configuration:

```bash
terraform apply
```
![apply](https://github.com/user-attachments/assets/ecd4486c-bd49-4255-a4e1-a4b684c474bb)

When prompted, type **"yes"** to confirm the apply operation.

### Step 6: Deployment Verification

![apply_finished](https://github.com/user-attachments/assets/a56d07cd-1d4e-4cdf-bd7d-8bd95d982db9)

1. Verify IPsec status in the CGW EC2 instance.

<img width="1109" alt="Screenshot 2024-08-27 at 14 49 01" src="https://github.com/user-attachments/assets/3e66e71e-bda7-4fc7-b44b-0cadd93111fa">

![IPsec_Status](https://github.com/user-attachments/assets/7c0c8515-554a-4279-97b9-ecb174739397)

2. Confirm VPN connection status in the App VPC region is **"UP"** (if it is not restart the IPsec service in CGW EC2)

![VPN_Status](https://github.com/user-attachments/assets/4f6904bf-de6f-44d3-89fc-6c2646dcedd9)

![Static routes](https://github.com/user-attachments/assets/3a114d94-c066-4112-a325-f02ffb6e5baf)

3. Use AWS Systems Manager Session Manager to log into one of the App VPC instances (e.g., **"AppInstance1"**).

  ![AppInstance1](https://github.com/user-attachments/assets/c1b43a29-c13c-4cb6-a140-5e7555d05863)

![ssm_app](https://github.com/user-attachments/assets/da3bf4d1-20d4-4e0a-80c1-47bc614ece60)

4. Test connectivity by pinging the Client EC2 instance's private IP from the App VPC instance.

![Client](https://github.com/user-attachments/assets/b6afe6f9-747b-4414-8dcc-adc476d9dcf2)

![App_Client](https://github.com/user-attachments/assets/ec398c81-2b3e-46a8-9eee-3c388eb14eb9)

5. From the Client EC2 instance, ping **AppInstance1** to confirm bi-directional connectivity.

![Client_App](https://github.com/user-attachments/assets/2fbd103c-a315-4887-a6fb-689d6b347595)


### Step 7: Test Web Application Access

1. Verify the health status of targets in the ALB Target Group :

  ![ALBTG](https://github.com/user-attachments/assets/6069505c-7281-4144-a16d-06e99a927bf9)

2. Confirm the DNSmasq service is operational in the CGW EC2 instance. :

  ![dnsmasq](https://github.com/user-attachments/assets/12972c59-d7d3-4baf-ae07-9e4e31c4eacf)

3. Test DNS resolution of "access.myapp.internal" from the Client EC2 instance. :

  ![dig_test](https://github.com/user-attachments/assets/a0ff694a-3776-40b5-9bab-70b13bb29780)

4. Execute the provided script on the client instance to verify web application accessibility.

![Screenshot 2024-08-27 at 15 48 58](https://github.com/user-attachments/assets/843edc38-1f3f-4b34-bb47-30148a279587)


## Project Teardown

Execute the following commands :

```bash
chmod +x scripts/empty_s3_bucket.sh 
terraform destroy
```

### Step 2: Destroy Terraform-managed Infrastructure

Execute the following command to destroy the Terraform-managed infrastructure:

```bash
terraform destroy
```

![destroy](https://github.com/user-attachments/assets/f36528a5-1788-4cc5-b8f5-3e21ff8cabaa)

Confirm the destruction when prompted.

## Notes

- The deployment process typically takes around **10 minutes** to complete.
- Always review and understand the changes before applying or destroying infrastructure.
- Ensure you have the necessary permissions in your AWS account to create and manage the resources defined in the Terraform configuration.
