##################### EXTRACT SG FOR PORT 80 & 443 #################

output "eks_nodes_sg" {
    value = aws_security_group.eks_nodes.id
}

output "database_sg" {
    value = aws_security_group.db_sg.id
}