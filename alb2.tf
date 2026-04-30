# alb2.tf

# 1. 대상 그룹
# main (8080)
resource "aws_lb_target_group" "st7-docker-main-tg" {
  name = "st7-docker-main-tg"
  port = 8080   # docker run -p 8080:80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc1.id

  # 인스턴스가 처음 시작하여 접속시 비율을 점진적으로 증가할 여유 시간
  slow_start = 30
  # 인스턴스 종료 시 기존 연결 유지 시간
  deregistration_delay = 30

  health_check {
    path    = "/"
    protocol = "HTTP"
    interval = 30   # 30초마다 헬스체크
    timeout = 5     # 5초 안에 응답이 없으면 실패로 간주
    healthy_threshold = 2   # 2번 연속 성공 시 healthy
    unhealthy_threshold = 3 # 3번 연속 실패 시 unhealthy
  }
}

# Install (8081)
resource "aws_lb_target_group" "st7-docker-install-tg" {
  name = "st7-docker-install-tg"
  port = 8081
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc1.id

  slow_start = 30
  deregistration_delay = 30

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# Command (8082)
resource "aws_lb_target_group" "st7-docker-command-tg" {
  name = "st7-docker-command-tg"
  port = 8082
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc1.id

  slow_start = 30
  deregistration_delay = 30

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# Build (8083)
resource "aws_lb_target_group" "st7-docker-build-tg" {
  name = "st7-docker-build-tg"
  port = 8083
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc1.id

  slow_start = 30
  deregistration_delay = 30

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# Compose (8084)
resource "aws_lb_target_group" "st7-docker-compose-tg" {
  name = "st7-docker-compose-tg"
  port = 8084
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc1.id

  slow_start = 30
  deregistration_delay = 30

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# Swarm (8085)
resource "aws_lb_target_group" "st7-docker-swarm-tg" {
  name = "st7-docker-swarm-tg"
  port = 8085
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc1.id

  slow_start = 30
  deregistration_delay = 30

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# Kubernetes (8086)
resource "aws_lb_target_group" "st7-docker-kubernetes-tg" {
  name = "st7-docker-kubernetes-tg"
  port = 8086
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc1.id

  slow_start = 30
  deregistration_delay = 30

  health_check {
    path = "/" # FastAPI 앱 설정에 따라 /docs 등으로 변경 가능
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# Board (8087)
resource "aws_lb_target_group" "st7-docker-board-tg" {
  name = "st7-docker-board-tg"
  port = 8087
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc1.id

  slow_start = 30
  deregistration_delay = 30

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

# ==========================================================================
# 2. 대상 그룹 인스턴스 등록

# ==========================================================================
# 3. ALB 생성
resource "aws_lb" "st7-docker-alb" {
  name = "st7-docker-alb"
  internal = false  # 내부 로드밸런서 설정
  load_balancer_type = "application" 
  security_groups = [data.aws_security_group.st7-alb-sg.id]
  subnets = [
    data.aws_subnets.st7-public-subnets.ids[0],
    data.aws_subnets.st7-public-subnets.ids[1]
  
  ]
  tags = { Name = "st7-docker-alb"}
}

# 4. ALB 리스너 생성
resource "aws_lb_listener" "st7-docker-alb-https-listener" {
  load_balancer_arn = aws_lb.st7-docker-alb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = ""  # ACM에서 발급받은 인증서 ARN

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-main-tg.arn
  }

  tags = { Name = "st7-alb-https-listener" }
  
}

# 5. ALB 리스너 규칙 생성
resource "aws_lb_listener" "st7-docker-alb-http-listener" {
  load_balancer_arn = aws_lb.st7-docker-alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol = "HTTPS"
      port = "443"
      status_code = "HTTP_301"
    }
  }

  tags = { Name = "st7-alb-http-listener" }
  
}

# ==========================================================================
# path 규칙 추가: install 경로로 들어오는 트래픽을 포트를 통해 대상 그룹으로 라우팅
# 1. Install Rule
resource "aws_lb_listener_rule" "st7-install-rule" {
  listener_arn = aws_lb_listener.st7-docker-alb-https-listener.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-install-tg.arn
  }
  condition {
    path_pattern {
      values = ["/install", "/install/*"]
    }
  }
}

# 2. Command Rule
resource "aws_lb_listener_rule" "st7-command-rule" {
  listener_arn = aws_lb_listener.st7-docker-alb-https-listener.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-command-tg.arn
  }
  condition {
    path_pattern {
      values = ["/command", "/command/*"]
    }
  }
}

# 3. Build Rule
resource "aws_lb_listener_rule" "st7-build-rule" {
  listener_arn = aws_lb_listener.st7-docker-alb-https-listener.arn
  priority     = 30
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-build-tg.arn
  }
  condition {
    path_pattern {
      values = ["/build", "/build/*"]
    }
  }
}

# 4. Compose Rule
resource "aws_lb_listener_rule" "st7-compose-rule" {
  listener_arn = aws_lb_listener.st7-docker-alb-https-listener.arn
  priority     = 40
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-compose-tg.arn
  }
  condition {
    path_pattern {
      values = ["/compose", "/compose/*"]
    }
  }
}

# 5. Swarm Rule
resource "aws_lb_listener_rule" "st7-swarm-rule" {
  listener_arn = aws_lb_listener.st7-docker-alb-https-listener.arn
  priority     = 50
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-swarm-tg.arn
  }
  condition {
    path_pattern {
      values = ["/swarm", "/swarm/*"]
    }
  }
}

# 6. Kubernetes Rule
resource "aws_lb_listener_rule" "st7-kubernetes-rule" {
  listener_arn = aws_lb_listener.st7-docker-alb-https-listener.arn
  priority     = 60
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-kubernetes-tg.arn
  }
  condition {
    path_pattern {
      values = ["/kubernetes", "/kubernetes/*"]
    }
  }
}

# 7. Board Rule
resource "aws_lb_listener_rule" "st7-board-rule" {
  listener_arn = aws_lb_listener.st7-docker-alb-https-listener.arn
  priority     = 70
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-board-tg.arn
  }
  condition {
    path_pattern {
      values = ["/board", "/board/*"]
    }
  }
}