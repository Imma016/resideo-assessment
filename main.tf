# Provider Configuration
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# VPC Resource
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Subnet Resources
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"   # Updated CIDR block to avoid conflicts
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"   # Updated CIDR block to avoid conflicts
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Internet Gateway Resource
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Security Group Resource
resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance Resource
resource "aws_instance" "web" {
  ami                    = "ami-063d43db0594b521b"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = "webkey"

  tags = {
    Name = "Terraform-EC2"
  }
}

# Application Load Balancer Resource
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_deletion_protection = false
}

# Updated Auto Scaling Group with Launch Template
resource "aws_launch_template" "app_lt" {
  name          = "app-launch-template"
  image_id      = "ami-063d43db0594b521b"
  instance_type = "t2.micro"
  key_name      = "webkey"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_ssh.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "autoscaling-group-instance"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.public1.id, aws_subnet.public2.id]
  
  # Using the new Launch Template
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "autoscaling-group-instance"
    propagate_at_launch = true
  }
}

