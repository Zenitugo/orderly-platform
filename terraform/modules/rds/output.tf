
output "rds_endpoint" {
    value = aws_db_instance.orderly_rds.address
}


output "rds_port" {
    value = aws_db_instance.orderly_rds.port
}



output "rds_db_name" {
    value = aws_db_instance.orderly_rds.db_name
}


output "rds_db_username" {
    value = aws_db_instance.orderly_rds.username
}

output "rds_password" {
    value = aws_db_instance.orderly_rds.manage_master_user_password
}