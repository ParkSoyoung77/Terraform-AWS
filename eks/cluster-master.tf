# cluster-master.tf

# 클러스터 마스터 역할 및 정책
resource "aws_iam_role" "cluster_role" {
    name = "st7-cluster-role"
    assume_role_policy = jsonencode(
        {
            Version ="2012-10-17",
            Statement = [
              {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = { Service = "eks.amazonaws.com" }
              }
            ]
        }
    )
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.cluster_role.name
}

# ==============================================================
# 워커노드의 역할 및 정책
resource "aws_iam_role" "node_role" {
    name = "st7-node-role"
    assume_role_policy = jsonencode(
        {
            Version ="2012-10-17",
            Statement = [
              {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = { Service = "ec2.amazonaws.com" }
              }
            ] 
        }
    )
}

# 반복문 사용을 통한 정책 부여를 위해 로컬 변수 선언
locals {
    node_policies = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",  
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",  
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"    
    ]
}

# 정책들을 role에 attachment
resource "aws_iam_role_policy_attachment" "node_attachment" {
    # toset은 리스트로 변경시켜주는 함수
    for_each = toset(local.node_policies)
    policy_arn = each.value
    role = aws_iam_role.node_role.name
}