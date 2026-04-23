# vpc-subnet.tf

# vpc 구성
# name은 테라폼 안에서 사용하는 이름
resource "aws_vpc" "st7-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "st7-vpc"
    }
}


# Public subnet 단일 구성
# resource "aws_subnet" "st7-2a-public-subnet" {
#     vpc_id = aws_vpc.st7-vpc.id
#     cidr_block = "10.0.1.0/24"
#     availability_zone = "ap-south-2a"

#     # 퍼블릭 서브넷 설정
#     # IPv4 주소 자동 할당: default(false)
#     map_public_ip_on_launch = true
#     # 시작 시 리소스 이름 DNS A 레코드 활성화: default(false)
#     enable_resource_name_dns_a_record_on_launch = true

#     tags = {
#         Name = "st7-2a-public-subnet"
#     }
# }