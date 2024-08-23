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

1. Configure AWS providers for the us-east-1 and us-east-2 regions.
2. Set up IAM roles, policies, and an S3 bucket for ALB access logs.
3. Create the Application VPC and Client VPC with necessary subnets, route tables, internet gateways, and NAT gateways.
4. Define security groups for various components in both VPCs.
5. Set up an ElastiCache Redis cluster in the Application VPC.
6. Launch EC2 instances for the application and client components, including the CGW instance.
7. Create an Application Load Balancer (ALB) in the Application VPC and attach the application instances.
8. Establish a Site-to-Site VPN connection between the Application VPC and the Client VPC.
9. Create a private hosted zone in Route53 with a DNS record pointing to the ALB, and set up Route53 Resolver endpoints for DNS resolution between VPCs.
10. Configure additional networking components, such as Elastic IP association, routing, and DHCP options for the Client VPC.

The project leverages modular components and user data scripts to create a secure and distributed application environment spanning two AWS regions, with the application running in one region and clients accessing it from another region through a secure VPN connection.
