###### Ouput the db secret ##########

output "db_secretarn" {
  value = module.rds.rds_secret_arn
}