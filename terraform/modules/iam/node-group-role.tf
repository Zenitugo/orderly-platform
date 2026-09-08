
#############################   CREATE ROLE FOR WORKER NODES #############################

resource "aws_iam_role" "node_group" {
    name                          = var.node_group_role_name
    assume_role_policy            = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "ec2.amazonaws.com"
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    })

}



################### ATTACH NODE GROUP ROLE TO AWS MANAGED POLICIES ########################

resource "aws_iam_role_policy_attachment" "WorkerPolicy" {
  policy_arn                      = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role                            = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "ContainerRegistry" {
  policy_arn                      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role                            = aws_iam_role.node_group.name
}