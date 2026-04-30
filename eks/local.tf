# local.tf

# local 상수 정의
locals {
  vpc_nameTag = "st7-vpc1"  # vpc 이름 태그 값
  subnet_ids = data.aws_subnets.st7_subnets.ids
}