provider "aws" {
    region     = "ap-south-1"
}

resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mydb" {
  engine                 = "mysql"
  db_name                = "mywezvadb"
  identifier             = "wezvadb"
  instance_class         = "db.t3.micro"
  engine_version         = "8.0.41"
  allocated_storage      = 20
  publicly_accessible    = true
  username               = "admin"
  password               = "wezvatech"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "wezvadb"
  }
}

