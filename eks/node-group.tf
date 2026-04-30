# node-group-tf

# 사용자 AMI를 이용한 시작 템플릿 생성
resource "aws_launch_template" "st7-lt" {
    # AMI 이미지: Amazon Linux 2023 중 EKS 지원 이미지
    # amazon-eks-node-al2023-x86_64-standard-1.35
    # ami-0fd01939d29afc17e
    image_id = "ami-0fd01939d29afc17e"
    name_prefix = "st7-lt-"    # 시작 템플릿 이름 접두사
    instance_type = "t3.large"  # EkS 사용 시 medium 이상
    key_name = "st7-key"

    network_interfaces {
      associate_public_ip_address = true # 퍼블릭 IP 할당 활성화
      
      # 보안 그룹
      security_groups = [
          data.aws_security_group.st7-ssh-sg.id,
          data.aws_security_group.eks_nodes_sg.id,
          # AWS의 EKS 마스터와의 통신을 위한 보안 그룹 정의
          # 아래 보안 그룹은 클러스터 생성과 함께 AWS에서 자동 생성하며 마스터에게 부여됨
          aws_eks_cluster.st7_cluster.vpc_config[0].cluster_security_group_id
      ]
    }

    # 중요: 시작 템플릿 업데이트 및 버전 단위의 설명
    update_default_version = true
    description = "Launch template for ASG EKS"

    # 유저 데이터 추가가능
    user_data = base64encode(<<-EOF
        ---
        apiVersion: node.eks.aws/v1alpha1
        kind: NodeConfig
        spec:
          cluster:
            name: ${aws_eks_cluster.st7_cluster.name}
            apiServerEndpoints:
              - ${aws_eks_cluster.st7_cluster.endpoint} # 리스트 형식으로 수정
            certificateAuthority: ${aws_eks_cluster.st7_cluster.certificate_authority[0].data}
            cidr: ${aws_eks_cluster.st7_cluster.kubernetes_network_config[0].service_ipv4_cidr}
    EOF
    )

    tag_specifications {
      resource_type = "instance"
      tags = { Name = "st7-eks-intance" }
    }

    tag_specifications {
      resource_type = "volume"
      tags = { Name = "st7-eks-instance-vol" }
    }
}

# node group 생성
resource "aws_eks_node_group" "st7_node_group" {
  cluster_name = aws_eks_cluster.st7_cluster.name
  node_group_name = "st7-nodes"
  node_role_arn = aws_iam_role.node_role.arn
  subnet_ids = data.aws_subnets.st7_subnets.ids

  # 노드 배포 환경 설정부
  scaling_config {
    desired_size = 2
    max_size = 3
    min_size = 1
  }

  # 시작 템플릿 정보
  launch_template {
    name = aws_launch_template.st7-lt.name
    version = "$Latest" # "$Default"
  }

  # 종속성 문제로 인한 적용 순서 강제 지정
  depends_on = [ aws_iam_role_policy_attachment.node_attachment ]
}