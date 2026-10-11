resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = var.cluster_name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [ var.eks_id,
  var.worker_nodes_id ]
}