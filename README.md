# Overview

This repository contains terraform code that creates an auto-scaling group in AWS and uses a AMI with preinstaleld nginx for the EC2 instances. It utilizes multi-AZ setup in a custom VPC. Also we have some rules and alarms defined for the autoscaling group to scale up if CPU utilization reaches 65% or more and scale down if it reaches 40% or below. Also the setup creates a MySQL RDS that is connected to the EC2 instances in the same VPC and is secured by security groups.

# Run the code
- Run `terraform init` to download all the needed modules and providers
- In the `default.auto.tfvars` file edit the security group config for the load balancer to allow NABs IPs. Currently it allows mine.
- Run `terraform plan`
- Run `terraform apply`
- You can see that the terraform code returns as an output a link to the load balancer which you can open to verify that nginx is working

## Notes
- I decided to use an image with already installed nginx by bitnami
- I have intentionally not allowed ssh access to the EC2 instances
- A random password is created for the database. You can also specify you own by providing the `password` parameter and setting `create_random_password = false` in the database module.
- We could also store the terraform state in a S3 bucket.
