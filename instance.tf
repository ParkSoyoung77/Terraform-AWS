# instance.tf

# Key pair 등록
# resource "aws_key_pair" "st7-ex-key" {
#     key_name = "st7-ex-key"
#     public_key = file("~/.ssh/st7-key.pem")
# }

# Amazone Linux 6.1: ami-0aa31b568c1e8d622  
resource "aws_instance" "st7-vpc-ec2" {
    ami = "ami-0aa31b568c1e8d622"
    instance_type = "t3.micro"

    # 퍼블릭 서브넷의 ID를 참조하여 연결
    subnet_id = aws_subnet.st7-public-subnets[0].id
    associate_public_ip_address = true

    # 볼륨 지정
    root_block_device {
        volume_size = 10
        volume_type = "gp3"
        delete_on_termination = true    # 인스턴스 삭제 시, 함께 삭제
    }

    # 키
    key_name = "st7-key"

    # 보안 그룹 정의
    vpc_security_group_ids = [
        aws_security_group.st7-ssh-sg.id
    ]

    # User Data
    # ${path.module} : .tf 파일 위치 경로
    # user_data = file("${path.module}/init.sh") 

    user_data = file("init.sh")

    # user_data = <<-EOF
    #     #!/bin/bash
    #     dnf update -y
    #     dnf install -y nginx

    #     systemctl enable nginx
    #     systemctl start nginx
    #     echo "<h1>Hello Nginx</h1>" > /usr/share/nginx/html/index.html  
    # EOF

    tags = { Name = "st7-vpc-ec2" }
}