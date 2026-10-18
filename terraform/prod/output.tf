###### Ouput the db secret ##########

output "db_secretarn" {
  value = module.rds.rds_secret_arn
}

output "api_gateway_repo" {
  value = module.ecr.api_gateway_repo
}


output "order_worker_repo" {
  value = module.ecr.order_worker_repo
}

output "notifier_repo" {
  value = module.ecr.notifier_repo
}

output "frontend_repo" {
  value = module.ecr.frontend_repo
}