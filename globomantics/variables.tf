# Provider variables
variable "aws_region" {
  type        = string
  description = "Region to use for AWS resources"
  default     = "us-east-1"
}

# Tag variables
variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "billing_code" {
  type        = string
  description = "Billing code for the project"
}

variable "company_name" {
  type        = string
  description = "Name of the company"
  default     = "Globomantics"
}

# Resource variables
variable "vpc_cidr_block" {
  type        = string
  description = "Base CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in the VPC"
  default     = true
}

variable "vpc_public_subnets_count" {
  type        = number
  description = "Number of public subnets to create"
  default     = 2
}

# variable "vpc_public_subnets_cidr_block" {
#   type        = list(string)
#   description = "CIDR block for the public subnets"
#   default     = ["10.0.0.0/24", "10.0.1.0/24"]
# }

variable "vpc_public_subnet_map_public_ip_on_launch" {
  type        = bool
  description = "Map public IP on launch for the subnet"
  default     = true
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances to create"
  default     = 2
}

variable "instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
  default     = "t2.micro"
}

variable "security_group_ingress_port" {
  type        = number
  description = "Port to allow ingress traffic"
  default     = 80
}

variable "security_group_egress_port" {
  type        = number
  description = "Port to allow ingress traffic"
  default     = 0
}

variable "naming_prefix" {
  type        = string
  description = "Prefix to use for naming resources"
  default     = "globo-web-app"
}

variable "environment" {
  type        = string
  description = "Environment to deploy the resources"
  default     = "dev"
}
