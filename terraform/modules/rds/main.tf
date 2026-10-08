# Create a subnet group for the RDS instance
resource "aws_db_subnet_group" "orderly_rds" {
  name       = "${var.project_name}_rds"
  subnet_ids = [var.private_subnet_1_id, var.private_subnet_2_id]
}

resource "aws_db_instance" "orderly_rds" {
  allocated_storage        = 20
  storage_type             = "gp2"
  engine                   = "postgres"
  engine_version           = "16.13"
  instance_class           = "db.t3.micro"
  db_name                  = "${var.project_name}"
  username                 = var.database_username
  db_subnet_group_name     = aws_db_subnet_group.orderly_rds.name
  vpc_security_group_ids   = [var.database_sg]
  publicly_accessible      = false
  multi_az                 = true
  skip_final_snapshot      = true
  manage_master_user_password = true
}