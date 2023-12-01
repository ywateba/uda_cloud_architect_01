provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.private_subnet1.id
}

resource "aws_eip" "main" {
  instance = aws_instance.nat.id
}

resource "aws_instance" "nat" {
  ami           = "ami-xxxxxxxxxxxxxxxxx"  # Replace with the appropriate NAT instance AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet1.id
}

resource "aws_instance" "web_servers" {
  ami           = "ami-xxxxxxxxxxxxxxxxx"  # Replace with the appropriate web server AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet1.id
}

resource "aws_instance" "app_servers" {
  ami           = "ami-xxxxxxxxxxxxxxxxx"  # Replace with the appropriate app server AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet1.id
}

resource "aws_db_instance" "rds_master" {
  identifier            = "rds-master"
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t2.micro"
  name                  = "mydb"
  username              = "admin"
  password              = "password"
  publicly_accessible   = false
  multi_az              = false
  availability_zone     = "us-east-1a"
}

resource "aws_db_instance" "rds_replica" {
  identifier            = "rds-replica"
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t2.micro"
  name                  = "mydb"
  username              = "admin"
  password              = "password"
  publicly_accessible   = false
  multi_az              = false
  availability_zone     = "us-east-1b"
}

resource "aws_lb" "web_servers_lb" {
  name               = "web-servers-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
}

resource "aws_lb" "app_servers_lb" {
  name               = "app-servers-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
}

resource "aws_security_group" "lb" {
  name        = "lb-sg"
  description = "Security group for load balancers"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "lb_ingress" {
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_servers_egress" {
  security_group_id = aws_security_group.lb.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_servers_egress" {
  security_group_id = aws_security_group.lb.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
