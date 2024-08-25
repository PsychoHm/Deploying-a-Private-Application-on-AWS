# Deploying a Private Application on AWS

## Project Overview

This project demonstrates the deployment of a private application on the AWS Cloud, accessible from an on-premises network through an AWS Site-to-Site VPN connection. The on-premises network is simulated using a Virtual Private Cloud (VPC) called the Client VPC, while the application resides in a separate VPC called the Application VPC. The two VPCs are deployed in different AWS regions (us-east-2 and us-east-1, respectively) and connected via a Site-to-Site VPN.

## Project Architecture 

![Screenshot 2024-08-23 at 12 51 18](https://github.com/user-attachments/assets/55857821-fc96-4581-8895-3182d1757fff)


## Infrastructure Components

### 1. Client VPC:

* Consists of two subnets: a private subnet hosting a client EC2 instance, and a public subnet hosting a Customer Gateway (CGW) instance.
* The client EC2 instance connects to the application using the DNS name access.myapp.internal through a Python script that sends GET requests every 20 seconds.
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
    - Associate the Elastic IP with the CGW instance.
    - Set up the necessary routes and DHCP options for proper communication between VPCs.

The deployment leverages various Terraform modules to create a secure, scalable, and distributed application environment across two AWS regions. The modular approach allows for easy management and potential expansion of the infrastructure.
