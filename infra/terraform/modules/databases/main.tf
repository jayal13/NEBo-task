# Security group for MongoDB
resource "aws_security_group" "mongodb_sg" {
  name        = "${var.name}-mongodb-sg"
  description = "SG for MongoDB"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "MongoDB Access"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] # Allow only your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    source = "terraform"
  }
}

# Security group for Redis
resource "aws_security_group" "redis_sg" {
  name        = "${var.name}-redis-sg"
  description = "SG for Redis"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "Redis Access"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] # Allow only your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    source = "terraform"
  }
}

# Security group for MySQL
resource "aws_security_group" "mysql_sg" {
  name        = "${var.name}-mysql-sg"
  description = "SG for MySQL"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "MySQL Access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] # Allow only your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    source = "terraform"
  }
}

# Creates an instance for MongoDB
resource "aws_instance" "mongodb" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  key_name               = var.key_pair

  tags = {
    source = "terraform"
  }
}

# Creates an instance for Redis
resource "aws_instance" "redis" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  key_name               = var.key_pair

  tags = {
    source = "terraform"
  }
}

# Creates an instance for MySQL
resource "aws_instance" "mysql" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  key_name               = var.key_pair

  tags = {
    source = "terraform"
  }
}

# Creates an .ini file for Ansible
resource "local_file" "databases" {
  content  = <<EOF
[mongodb]
${aws_instance.mongodb.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[redis]
${aws_instance.redis.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[mysql]
${aws_instance.mysql.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
  filename = "${path.module}/../../ansible/databases/inventory/host.ini"
}

