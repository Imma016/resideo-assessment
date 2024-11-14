variable "ami_id" {
  description = "AMI ID for EC2 instances"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "subnet_ids" {
  description = "Subnets for the Auto Scaling Group"
  type        = list(string)
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 3
}

variable "desired_capacity" {
  default = 2
}

variable "security_group_ids" {
  type = list(string)
}

variable "lb_security_group_id" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID"
}

