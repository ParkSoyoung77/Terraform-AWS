# asg.tf

# 사용자 AMI를 이용한 시작 템플릿 생성
resource "aws_launch_template" "st7-lt" {
    image_id = aws_ami_from_instance.st7-ami[0].id
    name_prefix = "st7-lt-"    # 시작 템플릿 이름 접두사
    instance_type = "t3.micro"
    key_name = "st7-key"

    vpc_security_group_ids = [
        data.aws_security_group.st7-alb-sg.id,
        data.aws_security_group.st7-http-sg.id,
        data.aws_security_group.st7-ssh-sg.id
    ]

    # 중요: 시작 템플릿 업데이트 및 버전 단위의 설명
    update_default_version = true
    description = "Launch template for ASG using custom AMI"

    tag_specifications {
      resource_type = "instance"
      tags = { Name = "st7-asg-intance" }
    }

    tag_specifications {
      resource_type = "volume"
      tags = { Name = "st7-asg-instance-vol" }
    }
}

# ==================================================
# 오토스케일링 그룹 생성
# 1. 개수에 대한 지정
resource "aws_autoscaling_group" "st7-ex-asg" {
    name = "st7-ex-asg"

    desired_capacity = 1
    max_size = 3
    min_size = 1
    
    launch_template {
      id = aws_launch_template.st7-lt.id
      version = "$Latest"  # $Default
    }

    # 위치할 서브넷 지정
    vpc_zone_identifier = [
        data.aws_subnets.st7-private-subnets.ids[0],
        data.aws_subnets.st7-private-subnets.ids[1],
        data.aws_subnets.st7-private-subnets.ids[2],
    ]

    # ASG의 인스턴스가 종료될 때 기존 연결 유지 시간
    lifecycle {
        ignore_changes = [desired_capacity]
    }

    # ALB와 연동하기 위한 Target Group ARN: 같은 종류만
    target_group_arns = [
        aws_lb_target_group.st7-docker-main-tg.arn,
        aws_lb_target_group.st7-docker-install-tg.arn
    ]

    # 헬스 체크
    health_check_type = "ELB"       # EC2: 인스턴스 상채 체크 / ELB: 엘라스틱 로드밸런서
    health_check_grace_period = 300 # 인스턴스 시작 후 초기화 대기 시간
}

# 2. 기준에 대한 지정
# 오토스케일링 그룹 인스턴스 조정 기준
resource "aws_autoscaling_policy" "st7-asg-policy" {
    name = "st7-asg-policy"
    autoscaling_group_name = aws_autoscaling_group.st7-ex-asg.name

    # 대상 추적 정책 유형
    # [권장] TargetTrackingScaling: 특정 지표가 목표값을 유지하도록 자동 조정
    # StepScaling: 지표가 특정 임계값을 초과할 때 단계적으로 조정
    # SimpleScaling: 지표가 특정 임계값을 초과할 때 단일 조정
    # PredictiveSacling: 과거 지표를 기반으로 미래 수요를 예측하여 조정
    policy_type = "TargetTrackingScaling"

    target_tracking_configuration {
      predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization" # ASG의 평균 cpu 사용률을 모니터링
      }
      target_value = 50.0 # CPU 사용률이 50%를 유지하도록 조정 (50%~70%)
    }
  
}