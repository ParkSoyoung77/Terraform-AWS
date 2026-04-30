# managed-user.tf

# 같은 리전을 쓰는 다른 사용자 정보
resource "aws_eks_access_entry" "manager" {
    for_each = toset(var.eks_admins)
    cluster_name = aws_eks_cluster.st7_cluster.name
    principal_arn = each.value
    kubernetes_groups = ["masters"]
    type = "STANDARD"
}

# 사용자에게 클러스터 권한 연결
# 터미널에서 aws eks list-access-policies으로 정책찾기
resource "aws_eks_access_policy_association" "manager" {
    for_each = toset(var.eks_admins)
    cluster_name = aws_eks_cluster.st7_cluster.name

    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

    # 리소스 이름 뒤에 바로 인덱스가 와야 합니다
    principal_arn = aws_eks_access_entry.manager[each.key].principal_arn

    access_scope {
      type = "cluster"  # 클러스터 사용 권한
    }

    depends_on = [ aws_eks_access_entry.manager ]  
}