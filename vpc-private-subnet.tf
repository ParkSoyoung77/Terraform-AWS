# vpc-private-subnet.tf

# Private subnet 다중 구성
resource "aws_subnet" "st7-2a-private-subnets" {
    count = 3
    vpc_id = aws_vpc.st7-vpc.id
    cidr_block = "10.0.${count.index + 11}.0/24"
    availability_zone = ["ap-south-2a", "ap-south-2b", "ap-south-2c"][count.index]

    tags = { Name = "st7-private${count.index + 1}-subnet" }
}

# NAT Gateway 구성
# Elastic IP 할당
resource "aws_eip" "st7-nat-eip" {
    domain = "vpc"
    tags = { Name = "st7-nat-eip" }
}

# NAT 게이트웨이 생성
resource "aws_nat_gateway" "st7-nat" {
    # eip 정의
    allocation_id = aws_eip.st7-nat-eip.id
    # 퍼블릭 서브넷 중 1개를 선택
    subnet_id = aws_subnet.st7-public-subnets[0].id
    # IGW를 지정하여 최종적인 대문을 정의
    depends_on = [ aws_internet_gateway.st7-vpc-igw ]
    
    tags = { Name = "st7-nat" }
}

# 프라이빗 라우팅 테이블
resource "aws_route_table" "st7-vpc-private-rt" {
    vpc_id = aws_vpc.st7-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.st7-nat.id
    }

    tags = { Name = "st7-vpc-private-rt" }
}

resource "aws_route_table_association" "st7-vpc-private-rt-assoc" {
    count = 3
    route_table_id = aws_route_table.st7-vpc-private-rt.id
    subnet_id = aws_subnet.st7-2a-private-subnets[count.index].id
}