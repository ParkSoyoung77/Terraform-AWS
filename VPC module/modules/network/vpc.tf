# vpc.tf

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "enable_dns_hostnames" {
  type = bool
}

variable "enable_dns_support" {
  type = bool
}

# ========================================================

locals {
  vpc_name             = var.vpc_name
  vpc_cidr             = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

}

# ========================================================

resource "aws_vpc" "st7_vpc" {
  cidr_block = local.vpc_cidr
  enable_dns_hostnames = local.enable_dns_hostnames
  enable_dns_support = local.enable_dns_support

  tags = {
    Name = "${var.vpc_name}"
  }
}

# ========================================================

output "vpc_id" {
  value       = aws_vpc.st7_vpc.id
}