########################## EXPORT IAM IDENTITIES ARN ##################
output "eks_cluster_role_arn" {
  value       = aws_iam_role.eks_cluster.arn
}


output "node_group_role_arn" {
    value = aws_iam_role.node_group.arn
}

output "ebs_csi_pod_identity_association" {
  value = aws_eks_pod_identity_association.ebs_csi.id
}

output "aws_load_balancer_controller_role_arn" {
  value       = aws_iam_role.lb_controller.arn
}