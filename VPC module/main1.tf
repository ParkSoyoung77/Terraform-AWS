# main.tf

module "network" {
  # 소스는 모듈 디렉토리 전체 경로
  source = "./modules/network"

  # 모듈로 값 전달: 모듈의 variable명 = 값 | local.변수 | var.변수
  vpc_name = "st7-vpc"
  vpc_cidr = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# main에서 값을 사용할 수 있도록 하기 위해서는 output 블럭 정의가 필요
output "vpc_id" {
  value = module.network.vpc_id
}