# security-group.tf

# alb-sg
resource "aws_security_group" "st7-alb-sg" {
    name = "st7-alb-sg"
    vpc_id = aws_vpc.st7-vpc.id
    description = "Allow HTTP and HTTPS Traffic"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0     # 모든 포트
        to_port     = 0
        protocol    = "-1"  # 모든 프로토콜
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "st7-alb-sg" }
}

# ssh-sg
resource "aws_security_group" "st7-ssh-sg" {
    name = "st7-ssh-sg"
    vpc_id = aws_vpc.st7-vpc.id
    description = "Allow SSH Traffic"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0     
        to_port     = 0
        protocol    = "-1" 
        cidr_blocks = ["0.0.0.0/0"]
    }
  
  tags = { Name = "st7-ssh-sg" }
}

# -------------------------------------------------
# http-sg
resource "aws_security_group" "st7-http-sg" {
    name = "st7-http-sg"
    vpc_id = aws_vpc.st7-vpc.id
    description = "Allow HTTP Traffic"

    egress {
        from_port   = 0     
        to_port     = 0
        protocol    = "-1" 
        cidr_blocks = ["0.0.0.0/0"]
    }
  
  tags = { Name = "st7-http-sg" }
}

# 보안 그룹 규칙 생성
# http-sg(대상)와 alb-sg(소스)를 연결
resource "aws_security_group_rule" "allow-alt-to-http" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"

    # 이 보안 규칙을 어디에 추가할 것인가
    security_group_id = aws_security_group.st7-http-sg.id
    # 누구를 추가할 것인가
    source_security_group_id = aws_security_group.st7-alb-sg.id
}