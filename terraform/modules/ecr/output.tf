################ EXTRACT ECR REPO URI ######################

output "api_gateway_repo" {
    value = aws_ecr_repository.api_gateway.repository_url
}


output "order_worker_repo" {
    value = aws_ecr_repository.order_worker.repository_url
}


output "notifier_repo" {
    value = aws_ecr_repository.notifier.repository_url
}

output "frontend_repo" {
    value = aws_ecr_repository.frontend.repository_url
}