terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "ac-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ac-vpc"
  }
}

resource "aws_subnet" "ac-public" {
  vpc_id     = aws_vpc.ac-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "ac-public-subnet"
  }
}