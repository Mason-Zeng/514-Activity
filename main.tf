//To get state file
terraform {
  backend "s3" {
    bucket         = "mason-zeng-terraform-bucket"   
    key            = "terraform.tfstate"    
    region         = "us-east-1"                   
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"  # Set AWS region to US East 1 (N. Virginia)
}

# Local variables block for configuration values
locals {
  aws_key = "MZ_AWS_Key"   # SSH key pair name for EC2 instance access
}

# Lookup the default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group to allow HTTP traffic
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow inbound HTTP traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "Allow HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EC2 instance resource definition
resource "aws_instance" "my_server" {
  ami           = data.aws_ami.amazonlinux.id  # Use the AMI ID from the data source
  instance_type = var.instance_type            # Use the instance type from variables
  key_name      = local.aws_key                # SSH key pair name for EC2 access

  # Attach the security group
  vpc_security_group_ids = [aws_security_group.allow_http.id]

  # Add tags to the EC2 instance for identification
  tags = {
    Name = "my ec2"
  }

  # Word Press initializer script
  user_data = file("${path.module}/wp_install.sh")
}