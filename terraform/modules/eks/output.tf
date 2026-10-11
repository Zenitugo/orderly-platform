######################## OUTPUT EKS ID ######################
output "eks_id" {
  value =  aws_eks_cluster.eks_cluster.id

  
}

output worker_nodes_id {
    value = aws_eks_node_group.eks_node_group.id
}