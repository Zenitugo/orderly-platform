#################### CREATE SECURITY GROUPS #####################
# resource "aws_security_group" "ssh_access" {
#     name = "${var.project_name}-ssh-access"
#     description = "ssh access"
#     vpc_id = var.vpc_id
#     ingress {
#         from_port = 22
#         to_port = 22
#         protocol = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     egress {
#         from_port = 0
#         to_port = 0
#         protocol = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }
# }



resource "aws_security_group" "http_access" {
    name = "${var.project_name}-http-access"
    description = "http access"
    vpc_id = var.vpc_id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}



resource "aws_security_group" "https_access" {
    name = "${var.project_name}-https-access"
    description = "https access"
    vpc_id = var.vpc_id
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "tcp"
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
        cidr_blocks = [aws_security_group.http_access.id, aws_security_group.https_access.id]
    }
}