# main.tf

# 1. 가용 영역 정보 가져오기
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. 로컬 변수 정의
locals {
  owner = "st7"
  az = data.aws_availability_zones.available.names
  vpc_cidr = "10.0.0.0/16"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"
  # vpc Name Tag
  name = "${local.owner}-vpc"
  # 사용할 가용영역 이름 정의
  azs = data.aws_availability_zones.available.names
  cidr = local.vpc_cidr

  # ================================================
  # subnet 설정
  # cidrsubnet("vpc_cidr", bit수, ip): cidrsubnet("10.0.0.0/16",8,1) => 10.0.1.0/24
  # for index, value in object(): 반복 내용
  # for ids, zone in local.azs: cidrsubnet(local.cidr,8,idx+1)
  public_subnets = [for idx, zone in local.az: cidrsubnet(local.vpc_cidr,8,idx+1)]
  public_subnet_names = [for idx, zone in local.az: "${local.owner}-public-${split("-",zone)[2]}-subnet"]

  # concat(): 두 값을 하나의 평면 구성의 연속된 값으로 병합: 각각의 컬렉션을 무너뜨려서 하나로
  private_subnets = concat(
    [for idx, zone in local.az: cidrsubnet(local.vpc_cidr,8,idx+11)],
    [for idx, zone in local.az: cidrsubnet(local.vpc_cidr,8,idx+21)]
  )
  private_subnet_names = concat(
    [for idx, zone in local.az: "${local.owner}-private-${split("-",zone)[2]}-subnet"],
    [for idx, zone in local.az: "${local.owner}-cluster-${split("-",zone)[2]}-subnet"]
    )

  database_subnets = [for idx, zone in local.az: cidrsubnet(local.vpc_cidr,8,idx+31)]
  database_subnet_names = [for idx, zone in local.az: "${local.owner}-db-${split("-",zone)[2]}-subnet"]

  # 완전 격리형 서브넷: NAT를 쓰지 않는 서브넷
  intra_subnets = []
  intra_subnet_names = []

  # 퍼블릭 서브넷의 인스턴스에 IPv4 자동 부여
  map_public_ip_on_launch = true
  # 해당 인스턴스의 프라이빗 DNS 이름에 대해 IPv4 주소(A레코드)를 자동으로 생성하고 연결할지를 설정
  public_subnet_enable_resource_name_dns_a_record_on_launch = true
  private_subnet_enable_resource_name_dns_a_record_on_launch = true
  database_subnet_enable_resource_name_dns_a_record_on_launch = false
  intra_subnet_enable_resource_name_dns_a_record_on_launch = false

  # ================================================
  # 게이트웨이 설정
  enable_nat_gateway = true
  single_nat_gateway = true # 1개의 NAT 생성
  # one_nat_gateway+pes_az = true # 각 AZ에 1개씩 생성: 고가용성

  # ================================================
  # 라우팅 설정
  manage_default_route_table = true
  default_route_table_name = "${local.owner}-default-rt"

  # 제어를 IGW에서 하므로 private 라우팅 설정은 빠진다
  create_multiple_public_route_tables = false
  create_multiple_intra_route_tables = false

  # 데이터베이스 자체 업데이트가 필요할 때: true
  create_database_subnet_route_table = false
  create_database_nat_gateway_route = false

  # ================================================
  # EKS 태그
  tags = {
    cluster = "${local.owner}-eks-cluster"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.owner}-eks-cluster" = "share" # owned
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.owner}-eks-cluster" = "shared" # owned
    "kubernetes.io/role/internal-elb" = "1"
  }

  igw_tags = { Name = "${local.owner}-cluster-igw" }
  nat_eip_tags = { Name = "${local.owner}-cluster-eip" }
  nat_gateway_tags = { Name = "${local.owner}-cluster-nat" }
  public_route_table_tags = { Name = "${local.owner}-cluster-public-rt" }
  private_route_table_tags = { Name = "${local.owner}-cluster-private-rt" }
}

# ==========================================================================
# vpc 엔드포인트 전용 서브모듈 호출
module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.0"

  vpc_id = module.vpc.vpc_id
  # security_group_ids = ["sg-123"] /443:vpc_cidr

  endpoints = {
    s3 = {
      # Gateway endpoint
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = concat(
        module.vpc.public_route_table_ids,
        module.vpc.private_route_table_ids
      )
      tags = { Name = "${local.owner}-s3-ep"}
    }
  }
}

resource "aws_security_group" "s3_endpoint_sg" {
  name = "${local.owner}-s3-endpoint-sg"
  vpc_id = module.vpc.vpc_id
  ingress = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr]
  }
  egress = {
      from_port   = 0     
      to_port     = 0
      protocol    = "-1"  
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.owner}-s3-endpoint-sg"}
}