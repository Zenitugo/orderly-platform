################ EXTRACT ECR REPO URI ######################

output "api-gateway-repo" {
    value = aws_ecr_repository.api_gateway.repository_url
}


output "order-worker-repo" {
    value = aws_ecr_repository.order_worker.repository_url
}


output "notifier-repo" {
    value = aws_ecr_repository.notifier.repository_url
}