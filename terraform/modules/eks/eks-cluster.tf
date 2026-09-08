######################### CREATE AN AWS ELASTIC KUBERNETES CLUSTER ###############

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.eks_cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = [var.private_subnet_1_id, var.private_subnet_2_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [ var.eks_cluster_role_arn ]
}