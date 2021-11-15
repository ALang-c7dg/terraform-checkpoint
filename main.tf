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

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ac-vpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "ac-route-table" {
  vpc_id = aws_vpc.ac-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "ac-route-table"
  }
}

resource "aws_route_table_association" "one" {
  subnet_id      = aws_subnet.ac-public.id
  route_table_id = aws_route_table.ac-route-table.id
}

resource "aws_security_group" "ac-sec-group" {
  name        = "ac-sec-group"
  description = "allowing http and ssh"
  vpc_id      = aws_vpc.ac-vpc.id

  # ingress {
  #   description      = "HTTP from VPC"
  #   from_port        = 80
  #   to_port          = 80
  #   protocol         = "http"
  #   cidr_blocks      = [aws_vpc.ac-vpc.cidr_block]
  # }

  # ingress {
  #   description      = "SSH from VPC"
  #   from_port        = 22
  #   to_port          = 22
  #   protocol         = "ssh"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

//deleted egress rule
  tags = {
    Name = "ac-sec-group"
  }
}

// HTTP: 80, SSH: 22 from 0.0.0.0/0

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.ac-vpc.cidr_block]
  security_group_id = aws_security_group.ac-sec-group.id
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ac-sec-group.id
}
//create EC2
resource "aws_instance" "ac-ec2" {
  ami           = "ami-04ad2567c9e3d7893" 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ac-sec-group.id]
  associate_public_ip_address = true
  subnet_id = aws_subnet.ac-public.id
  key_name = "TerraformCP"
  user_data = "${file("install.sh")}"

  tags = {
    Name = "ac-ec2"
  }
}

output "ec2_public_ip" {
  value = aws_instance.ac-ec2.public_ip
}