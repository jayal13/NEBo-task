
# 1) Segunda VPC: "Nube privada"
resource "aws_vpc" "private_vpc" {
  cidr_block = var.private_vpc_cidr
  tags = {
    Name   = "${var.name}-private-vpc"
    source = "terraform"
  }
}

# 2) Subnet en la VPC privada
resource "aws_subnet" "private_side_subnet" {
  vpc_id                  = aws_vpc.private_vpc.id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false
  tags = {
    Name   = "${var.name}-private-subnet"
    source = "terraform"
  }
}

# 3) Route Table + Association (no IGW, para mantenerla privada)
resource "aws_route_table" "private_side_rt" {
  vpc_id = aws_vpc.private_vpc.id
  tags = {
    Name   = "${var.name}-private-rt"
    source = "terraform"
  }
}

resource "aws_route_table_association" "private_side_assoc" {
  subnet_id      = aws_subnet.private_side_subnet.id
  route_table_id = aws_route_table.private_side_rt.id
}

# 4) VPC Peering Connection (auto_accept para simplificar)
resource "aws_vpc_peering_connection" "public_private_peering" {
  vpc_id      = var.vpc_id
  peer_vpc_id = aws_vpc.private_vpc.id
  auto_accept = true

  tags = {
    Name   = "${var.name}-public-private-peering"
    source = "terraform"
  }
}

# 5) Rutas en la VPC principal (para llegar a la VPC privada: 10.1.0.0/16)
#    a) En la RT "public"
resource "aws_route" "main_public_to_private" {
  route_table_id            = var.public_route_table
  destination_cidr_block    = var.private_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.public_private_peering.id

  depends_on = [aws_vpc_peering_connection.public_private_peering]
}

#    b) En la RT default o en la que use la subnet privada (si quieres que la subnet privada
#       también alcance la segunda VPC). Si no definiste una route table "private", 
#       podrías apuntar a la main route table usando "aws_vpc.main.default_route_table_id".
resource "aws_route" "main_private_to_private" {
  route_table_id            = var.vpc_route_table_id
  destination_cidr_block    = var.private_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.public_private_peering.id

  depends_on = [aws_vpc_peering_connection.public_private_peering]
}

# 6) Rutas en la VPC privada (para llegar a la VPC principal: var.vpc_ip)
resource "aws_route" "private_side_to_main" {
  route_table_id            = aws_route_table.private_side_rt.id
  destination_cidr_block    = var.vpc_ip
  vpc_peering_connection_id = aws_vpc_peering_connection.public_private_peering.id

  depends_on = [aws_vpc_peering_connection.public_private_peering]
}

# 7) Ejemplo: Instancia en la VPC privada
resource "aws_security_group" "private_app_sg" {
  name        = "${var.name}-private-app-sg"
  vpc_id      = aws_vpc.private_vpc.id
  description = "SG for private app"

  # Permite SSH solo desde la VPC principal (10.0.0.0/16) via peering
  # (Asumiendo var.vpc_ip = 10.0.0.0/16)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_ip]
  }

  # Egress libre
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

resource "aws_instance" "private_app" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_side_subnet.id
  vpc_security_group_ids = [aws_security_group.private_app_sg.id]
  key_name               = var.key_pair

  tags = {
    Name   = "${var.name}-private-app"
    source = "terraform"
  }
}