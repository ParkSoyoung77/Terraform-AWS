# data.tf

# 가용영역 정보
data "aws_availability_zones" "az" {
    state = "available"
}

# VPC 정보
data "aws_vpc" "st7-vpc" {
    filter{
        name    = "tag:Name"
        values  = ["st7-vpc"]
    }
}

# Public Subnet 정보
data "aws_subnets" "st7-public-subnets" {
    filter {
      name   = "tag:Name"
      values = ["st7-public1-subnet", "st7-public2-subnet", "st7-public3-subnet"]
    }
}

# Private Subnet 정보
data "aws_subnets" "st7-private-subnets" {
    filter {
      name   = "tag:Name"
      values = ["st7-private1-subnet", "st7-private2-subnet", "st7-private3-subnet"]
    }
}

# 보안 그룹 정보
data "aws_security_group" "st7-alb-sg" {
  filter {
    name    = "tag:Name"
    values  = ["st7-alb-sg"]
  }
    vpc_id = data.aws_vpc.st7-vpc.id
}

data "aws_security_group" "st7-http-sg" {
  filter {
    name    = "tag:Name"
    values  = ["st7-http-sg"]
  }
    vpc_id = data.aws_vpc.st7-vpc.id
}

data "aws_security_group" "st7-ssh-sg" {
  filter {
    name   = "tag:Name"
    values = ["st7-ssh-sg"]
  }
    vpc_id = data.aws_vpc.st7-vpc.id
}