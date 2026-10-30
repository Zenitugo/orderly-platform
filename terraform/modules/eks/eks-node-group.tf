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
    desired_size           = var.desired_size
    max_size               = var.max_size
    min_size               = var.min_size
  }

  update_config {
    max_unavailable        = 1
  }

  labels = {
    workload = var.app_workload
  }

  tags = {
    Name = var.node_group_name
  }

}



#################### OBSERVABILITY LAUNCH TEMPLATE ####################

resource "aws_launch_template" "observability_nodes_template" {
  name_prefix   = "${var.observability_node_group_name}-template"
  instance_type = var.observability_instance_type

  vpc_security_group_ids = [
    var.eks_nodes_sg,
    aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.observability_node_group_name
      Role = "observability"
    }
  }
}

#################### OBSERVABILITY EKS NODE GROUP ####################

resource "aws_eks_node_group" "observability_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.observability_node_group_name
  node_role_arn   = var.node_group_role_arn

  subnet_ids = [
    var.private_subnet_1_id,
    var.private_subnet_2_id
  ]

  capacity_type = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.observability_nodes_template.id
    version = aws_launch_template.observability_nodes_template.latest_version
  }

  scaling_config {
    desired_size = var.observability_desired_size
    min_size     = var.observability_min_size
    max_size     = var.observability_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    workload = var.monitoring_workload
  }

  tags = {
    Name = var.observability_node_group_name
    Role = "observability"
  }
}
