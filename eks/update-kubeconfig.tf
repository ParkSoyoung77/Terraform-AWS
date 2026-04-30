# update-kubeconfig.tf

resource "null_resource" "update_kubeconfig" {
    # 노드 그룹이 생성 완료된 후 실행되도록 설정
    depends_on = [ aws_eks_node_group.st7_node_group ]

    provisioner "local-exec" {
      # .name 대신 .id를 사용하여 Deprecated Warning 해결
      # coomand = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
      command = "aws eks update-kubeconfig --region ap-south-2 --name ${aws_eks_cluster.st7_cluster.name}"
    }
}