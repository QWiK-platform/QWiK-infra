# -- rds subnet group
resource "aws_db_subnet_group" "this" {
  name       = "qwik-rds-subnet-group"
  subnet_ids = module.network.private_subnet_ids

  tags = {
    Name = "qwik-rds-subnet-group"
  }
}

# -- rds instance
resource "aws_db_instance" "this" {
  identifier     = "qwik-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name = "qwik-db"
  }
}