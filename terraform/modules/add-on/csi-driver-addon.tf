####################### Deploy the AWS EBS CSI Driver Addon #############################
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.66.0-eksbuild.1" 

   depends_on = [
    aws_eks_addon.pod_identity_agent,
    var.ebs_csi_pod_identity_association
  ]

  # Optional: Handle what happens if conflict occurs during overwrite
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}