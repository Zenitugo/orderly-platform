####################### SSM PARAMETER STORE ###################

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/${var.project_name}/${var.environment_name}/db/host"
  type        = "String"
  value       = module.rds.rds_endpoint
  tags = {
    Environment = var.environment_name
  }
}


resource "aws_ssm_parameter" "db_port" {
  name        = "/${var.project_name}/${var.environment_name}/db/port"
  type        = "String"
  value       = module.rds.rds_port
  tags = {
    Environment = var.environment_name
  }
}


resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.project_name}/${var.environment_name}/db/name"
  type        = "String"
  value       = module.rds.rds_db_name
  tags = {
    Environment = var.environment_name
  }
}


resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/${var.environment_name}/db/username"
  type        = "String"
  value       = module.rds.rds_db_username
  tags = {
    Environment = var.environment_name
  }
}

resource "aws_ssm_parameter" "api_gateway_image" {
  name        = "/${var.project_name}/${var.environment_name}/ecr/api-gateway"
  type        = "String"
  value       = module.ecr.api_gateway_repo
  tags = {
    Environment = var.environment_name
  }
}


resource "aws_ssm_parameter" "order_worker_image" {
  name        = "/${var.project_name}/${var.environment_name}/ecr/order-worker"
  type        = "String"
  value       = module.ecr.order_worker_repo
  tags = {
    Environment = var.environment_name
  }
}

resource "aws_ssm_parameter" "notifier_image" {
  name        = "/${var.project_name}/${var.environment_name}/ecr/notifier"
  type        = "String"
  value       = module.ecr.notifier_repo
  tags = {
    Environment = var.environment_name
  }
}

