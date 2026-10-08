
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

output "rds_secret_arn" {
    value = aws_db_instance.orderly_rds.master_user_secret[0].secret_arn
}