
# Create the EKS NODE GROUP
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  node_group_name          = var.node_group_name
  node_role_arn            = var.node_group_role_arn
  subnet_ids               = [ var.private_subnet_1_id, var.private_subnet_2_id]

  capacity_type = "ON_DEMAND"
  

  scaling_config {
    desired_size           = 2
    max_size               = 3
    min_size               = 1
  }

  update_config {
    max_unavailable        = 1
  }

  instance_types           = [var.instance_type]

  tags = {
    Name = var.node_group_name
  }

}