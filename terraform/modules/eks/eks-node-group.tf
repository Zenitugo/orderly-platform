#################### Create a launch template for worker nodes ############################
resource "aws_launch_template" "worker_nodes_template" {
  name_prefix = "${var.node_group_name}-template"
  instance_type           = var.instance_type
  vpc_security_group_ids = [
    var.eks_nodes_sg,
    aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id]
}

#################### Create the EKS NODE GROUP #################################
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  node_group_name          = var.node_group_name
  node_role_arn            = var.node_group_role_arn
  subnet_ids               = [ var.private_subnet_1_id, var.private_subnet_2_id]

  capacity_type = "ON_DEMAND"
  
  launch_template {
    id = aws_launch_template.worker_nodes_template.id
    version = aws_launch_template.worker_nodes_template.latest_version
  }

  scaling_config {
    desired_size           = 2
    max_size               = 3
    min_size               = 1
  }

  update_config {
    max_unavailable        = 1
  }

  tags = {
    Name = var.node_group_name
  }

}