# vpc-pbulic-subnet.tf

# Public subnet 다중 구성
resource "aws_subnet" "st7-public-subnets" {
    count = 3 # count가 포함된 리소스를 지정된 횟수만큼 반복(첫 번째 라인에 위치)
    vpc_id = aws_vpc.st7-vpc.id
    # 문자열("")안에서의 연산은 ${}안에 작성
    cidr_block = "10.0.${count.index + 1}.0/24"
    # availability_zone = data.aws_availability_zone.available.names[count.index]
    availability_zone = ["ap-south-2a", "ap-south-2b", "ap-south-2c"][count.index]

    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true

        tags = {
        Name = "st7-public${count.index + 1}-subnet"
    } 
}

# Internet Gateway 구성
resource "aws_internet_gateway" "st7-vpc-igw" {
    vpc_id = aws_vpc.st7-vpc.id
    tags = {
        Name = "st7-vpc-igw"
    } 
}

# 퍼블릭 라우팅 테이블
resource "aws_route_table" "st7-vpc-public-rt" {
    vpc_id = aws_vpc.st7-vpc.id

    route {
        # 목적지 주소 범위
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.st7-vpc-igw.id
    }

    tags = {
        Name = "st7-vpc-public-rt"
    }
}

resource "aws_route_table_association" "st7-vpc-public-rt-assoc" {
    count = 3
    route_table_id = aws_route_table.st7-vpc-public-rt.id
    subnet_id = aws_subnet.st7-public-subnets[count.index].id

}