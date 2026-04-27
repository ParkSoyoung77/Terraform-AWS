# instance.tf

resource "aws_security_group_rule" "st7-http-sg" {
    type        = "ingress"
    from_port   = 8080
    to_port     = 8085
    protocol    = "tcp"

    security_group_id        = data.aws_security_group.st7-http-sg.id
    source_security_group_id = data.aws_security_group.st7-alb-sg.id
}

resource "aws_instance" "st7-alb-instance" {
    count = 1
    ami   = "ami-0aa31b568c1e8d622" # AL2023 AMI 확인 필요
    instance_type = "t3.micro"

    subnet_id = data.aws_subnets.st7-public-subnets.ids[0]
    associate_public_ip_address = true

    root_block_device {
        volume_size           = 10
        volume_type           = "gp3"
        delete_on_termination = true
    }

    key_name = "st7-key"

    vpc_security_group_ids = [
        data.aws_security_group.st7-ssh-sg.id,
        data.aws_security_group.st7-http-sg.id
    ]

    # 스크립트 내용을 직접 삽입 (EOF 사용)
    user_data = <<-EOF
                #!/bin/bash
                # 로그 기록 설정
                exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
                echo "### Starting Setup for AL2023 ###"

                # 1. 패키지 설치 및 Docker 활성화
                dnf update -y
                dnf install -y docker wget
                systemctl enable --now docker
                usermod -aG docker ec2-user

                # 2. Docker Compose V2 설치
                mkdir -p /usr/lib/docker/cli-plugins
                curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/lib/docker/cli-plugins/docker-compose
                chmod +x /usr/lib/docker/cli-plugins/docker-compose
                ln -s /usr/lib/docker/cli-plugins/docker-compose /usr/bin/docker-compose

                # 3. 프로젝트 설정 및 파일 다운로드
                PROJECT_DIR="/home/ec2-user/project"
                mkdir -p $PROJECT_DIR
                cd $PROJECT_DIR

                # sy님의 최신 YAML 다운로드 (8082: fastapi 포함 버전)
                wget https://raw.githubusercontent.com/ParkSoyoung77/aa/main/docker-compose-alb.yaml -O docker-compose-alb.yaml

                # 4. 권한 수정 및 컨테이너 실행
                chown -R ec2-user:ec2-user $PROJECT_DIR
                
                # 기존 컨테이너를 확실히 정리하고 새 이미지를 가져와 실행
                docker-compose -f docker-compose-alb.yaml down --remove-orphans
                docker-compose -f docker-compose-alb.yaml up -d --pull always

                sleep 10

                # 5. Nginx 8081 컨테이너 경로 작업 (물리적 파일 서버이므로 필수)
                docker exec -u root docker-install-nginx-container mkdir -p /usr/share/nginx/html/install
                docker exec -u root docker-install-nginx-container cp /usr/share/nginx/html/index.html /usr/share/nginx/html/install/

                echo "### Setup Complete! ###"
                EOF

    # User Data가 수정되면 인스턴스를 자동으로 재생성하도록 설정
    user_data_replace_on_change = true

    tags = { Name = "st7-vpc-instance" }
}

# =============================================================
# AMI 인스턴스 생성
resource "aws_ami_from_instance" "st7-ami" {
    count = 1
    name = "st7-ami"
    # AMI를 생성할 인스턴스 정의
    source_instance_id = aws_instance.st7-alb-instance[count.index].id

    # snapshot 생성 시 루트 볼륨만 포함하도록 설정
    # true: 인스턴스를 종료하지 않고 실행 중인 상태에서 AMI 생성
    # default(false): 인스턴스를 일시적으로 종료하여 AMI 생성
    snapshot_without_reboot = false

    tags = { Name = "st7-ami" }
}