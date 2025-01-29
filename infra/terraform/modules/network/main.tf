# Creates a VPC that is the container of subnet, instances, gateway, etc.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_ip
  tags = {
    source = "terraform"
  }
}

# Creates a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_ip
  map_public_ip_on_launch = true # This option set the subnet as public
  tags = {
    source = "terraform"
  }
}

# Creates a private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_ip
  map_public_ip_on_launch = false # This option set the subnet as private
  tags = {
    source = "terraform"
  }
}

# Creates an internet gateway, that alows the communication between vpc and public internet,
# is mandatory if we whant to create a public subnet reachable from internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    source = "terraform"
  }
}

# Create a rout table that specifies how packets are forwarded between the subnets within your VPC,
# the internet, and your VPN connection.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.route_table_ips
    content {
      cidr_block = route.value
      gateway_id = aws_internet_gateway.gw.id
    }
  }
  tags = {
    source = "terraform"
  }
}

# Associate a route table to a subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}