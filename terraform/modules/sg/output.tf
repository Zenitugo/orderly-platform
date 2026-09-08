##################### EXTRACT SG FOR PORT 80 & 443 #################

output "http_sg" {
    value = aws_security_group.http_access.id
}


output "https_sg" {
    value = aws_security_group.https_access.id
}
