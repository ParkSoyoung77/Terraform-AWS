# output.tf

output "az_name" {
    value       = data.aws_availability_zones.az.names
    description = "사용 가능한 가용영역 정보"
}

output "vpc_id" {
    value = data.aws_vpc.st7-vpc.id
}

output "public_subnets_id" {
    value = data.aws_subnets.st7-public-subnets.ids
}

output "private_subnets_id" {
    value = data.aws_subnets.st7-private-subnets.ids
}

output "alb_sg_id" {
    value = data.aws_security_group.st7-alb-sg.id
}

output "alb_http_id" {
    value = data.aws_security_group.st7-http-sg.id
}


# dns 출력
output "docker-alb-dns-name" {
    value = aws_lb.st7-docker-alb.dns_name
    description = "ALB의 DNS 이름"
}

# 시작 템플릿
output "launch_template_latest_version" {
    value = aws_launch_template.st7-lt.latest_version
    description = "시작 템플릿의 최신 버전"
}

output "launch_template_default_version" {
    value = aws_launch_template.st7-lt.default_version
    description = "시작 템플릿의 기본 버전"
}

output "launch_template_description" {
  value = aws_launch_template.st7-lt.description
  description = "시작 템플릿 설명"
}