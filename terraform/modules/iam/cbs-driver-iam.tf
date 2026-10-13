######################### RETRIEVE CBS DRIVER POLICY ###########################
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["://amazonaws.com"] 
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}



######################## CREATEB IAM ROLE FOR EBS CSI DRIVER ############################
resource "aws_iam_role" "ebs_csi" {
    name = "${var.cluster_name}-ebs-csi-role"
    assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}


######################## ATTACH EBS CSI PERMISSIONS ################################
resource "aws_iam_role_policy_attachment" "ebs_csi"{
    role = aws_iam_role.ebs_csi.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}



################# ASSOCIATE EKS POD IDENTITY WITH EBS CSI DRIVER ###################
resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"              # <-- Must be kube-system
  service_account = "ebs-csi-controller-sa"     # <-- Must match the driver's exact SA name
  role_arn        = aws_iam_role.ebs_csi.arn    # <-- Your IAM role with AmazonEBSCSIDriverPolic

  # FIX: Reference your actual resources here instead of var.*_id
  depends_on = [ 
    var.eks_id, 
    var.worker_nodes_id 
  ]
}