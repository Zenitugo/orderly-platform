################## CREATE ECR REPO FOR API GATEWAY ############################
resource "aws_ecr_repository" "api_gateway" {
  name = "${var.project_name}-apigateway"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}


##################  CREATE ECR REPO FOR ORDER WORKER ########################
resource "aws_ecr_repository" "order_worker" {
  name = "${var.project_name}-orderworker"       
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
