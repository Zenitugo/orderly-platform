############## CREATE IAM POLICY FOR EXTERNAL SECRETS ####################

resource "aws_iam_policy" "external_secrets" {
  name = "${var.project_name}-external-secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.rds_secret_arn
      },
      {
        Effect = "Allow"
        Action =[
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = var.db_parameter_arns
      }
    ]
  })
}


######################## CREATE IAM ROLE FOR EXTERNAL SECRETS ########################

resource "aws_iam_role" "external_secrets" {
  name = "${var.project_name}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}





######################## ATTACH SECRETS POLICY ########################

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role = aws_iam_role.external_secrets.name

  policy_arn = aws_iam_policy.external_secrets.arn
}

################# ASSOCIATE EKS POD IDENTITY WITH EXTERNAL SECRETS ###################
resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = var.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets.arn

  depends_on = [ var.eks_id,
  var.worker_nodes_id ]
}