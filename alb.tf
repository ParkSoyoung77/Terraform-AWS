# alb.tf

# 1. 대상 그룹
resource "aws_lb_target_group" "st7-docker-main-tg" {
  name = "st7-docker-main-tg"
  port = 8080   # docker run -p 8080:80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc.id

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

resource "aws_lb_target_group" "st7-docker-install-tg" {
  name = "st7-docker-install-tg"
  port = 8081   # docker run -p 8081:80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc.id

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

resource "aws_lb_target_group" "st7-docker-fastapi-tg" {
  name = "st7-docker-fastapi-tg"
  port = 8082   # docker run -p 8082:80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.st7-vpc.id

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

# ==========================================================================
# 2. 대상 그룹 인스턴스 등록
resource "aws_lb_target_group_attachment" "st7-docker-main-tg-attachment" {
  count = 1
  # 어느 대상 그룹에 등록할 것인가?
  target_group_arn = aws_lb_target_group.st7-docker-main-tg.arn
  target_id = aws_instance.st7-alb-instance[count.index].id
  port      = 8080  #대상그룹의 포트와 일치
  
}

resource "aws_lb_target_group_attachment" "st7-docker-install-tg-attachment" {
  count = 1
  # 어느 대상 그룹에 등록할 것인가?
  target_group_arn = aws_lb_target_group.st7-docker-install-tg.arn
  target_id = aws_instance.st7-alb-instance[count.index].id
  port      = 8081  #대상그룹의 포트와 일치
  
}

resource "aws_lb_target_group_attachment" "st7-docker-fastapi-tg-attachment" {
  count = 1
  # 어느 대상 그룹에 등록할 것인가?
  target_group_arn = aws_lb_target_group.st7-docker-fastapi-tg.arn
  target_id = aws_instance.st7-alb-instance[count.index].id
  port      = 8082  #대상그룹의 포트와 일치
  
}

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
# install path 규칙 추가: install 경로로 들어오는 트래픽을 8081포트 대상 그룹으로 라우팅
resource "aws_lb_listener_rule" "st7-install-path-install-rule" {
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

# fastapi path 규칙 추가: api 경로로 들어오는 트래픽을 8082포트 대상 그룹으로 라우팅
resource "aws_lb_listener_rule" "st7-api-path-fastapi-rule" {
  listener_arn = aws_lb_listener.st7-docker-alb-https-listener.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.st7-docker-fastapi-tg.arn
  }

  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}