################## CREATE ECR REPO FOR API GATEWAY ############################
resource "aws_ecr_repository" "api-gateway" {
  name = "${var.project_name}-api-gateway"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}


##################  CREATE ECR REPO FOR ORDER WORKER ########################
resource "aws_ecr_repository" "order-worker" {
  name = "${var.project_name}-order-worker"       
  image_tag_mutability = "MUTABLE"
  force_delete = true
  
  image_scanning_configuration {
        scan_on_push = true
    }
}



#################### CREATE ECR REPO FOR NOTIFIER #################################
resource "aws_ecr_repository" "notifier" {
  name = "${var.project_name}-notifier"       
  image_tag_mutability = "MUTABLE"
  force_delete = true
  
  image_scanning_configuration {
        scan_on_push = true
    }
}
