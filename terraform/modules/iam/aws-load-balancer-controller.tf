
# IAM policy for the AWS Load Balancer Controller
resource "aws_iam_policy" "lb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM policy for the AWS Load Balancer Controller in EKS"

  policy = file("${path.module}/aws-load-balancer-controller-policy.json")
}


# Dedicated IAM role for the controller
resource "aws_iam_role" "lb_controller" {
  name               = "${var.cluster_name}-lb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role.json
}

# Attach controller permissions
resource "aws_iam_role_policy_attachment" "lb_controller_attach" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

# Associate the IAM role with the controller's Kubernetes service account
resource "aws_eks_pod_identity_association" "lb_controller" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lb_controller.arn

  depends_on = [ var.eks_id,
  var.worker_nodes_id  ]
}


