#################### CREATE SECURITY GROUPS #####################
resource "aws_security_group" "eks_nodes" {
    name        = "${var.project_name}-eks-nodes"
    description = "Security group for EKS worker nodes"
    vpc_id      = var.vpc_id

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "db_sg" {
    name = "${var.project_name}-db-sg"
    description = "security group for database"
    vpc_id = var.vpc_id


    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        security_groups = [aws_security_group.eks_nodes.id]
    }

    egress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}