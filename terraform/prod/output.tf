#Ouput the db values
output "db_endpoint" {
    value = module.rds.rds_endpoint
}


output "db_port" {
    value = module.rds.rds_port
}


output "db_name" {
    value = module.rds.rds_db_name
}

output "db_username" {
    value = module.rds.rds_db_username
}

output "db_secretarn" {
  value = module.rds.rds_secret_arn
}