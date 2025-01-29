provider "aws" {
  region = var.region
}

# Obtains the metadata of the secret
data "aws_secretsmanager_secret" "ssh_keys" {
  name = "amazon_ssh_keys"
}

# Obtain the secret
data "aws_secretsmanager_secret_version" "ssh_keys_version" {
  secret_id = data.aws_secretsmanager_secret.ssh_keys.id
}

# Retrieves the secret as a map
locals {
  ssh_keys = jsondecode(data.aws_secretsmanager_secret_version.ssh_keys_version.secret_string)
}

# Retrieves the IP address of who is running Terraform
data "http" "my_ip" {
  url = "http://ifconfig.me"
}

module "network" {
  source = "./modules/network"

  region            = var.region
  vpc_ip            = var.vpc_ip
  public_subnet_ip  = var.public_subnet_ip
  private_subnet_ip = var.private_subnet_ip
  route_table_ips   = var.route_table_ips
  name              = var.name
  my_ip             = data.http.my_ip.body
}

# Módulo de instancias y SG básicos
module "compute" {
  source = "./modules/compute"

  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id
  my_ip            = data.http.my_ip.body
  public_ssh_key   = local.ssh_keys.public_ssh_key
  name             = var.name
  ami              = var.ami
  instance_type    = var.instance_type
  ebs_size         = var.ebs_size
  private_ssh_key  = var.private_ssh_key
}

# Módulo de AutoScaling
module "autoscaling" {
  source = "./modules/autoscaling"

  key_pair         = module.compute.key_pair
  public_subnet_id = module.network.public_subnet_id
  sg_id            = module.compute.sg_id
  ami              = var.ami
  instance_type    = var.instance_type
  name             = var.name
}

# Módulo de bases de datos (MongoDB, Redis, MySQL, etc.)
module "databases" {
  source = "./modules/databases"

  key_pair           = module.compute.key_pair
  vpc_id             = module.network.vpc_id
  public_subnet_id   = module.network.public_subnet_id
  public_route_table = module.network.public_route_table
  my_ip              = data.http.my_ip.body
  public_ssh_key     = local.ssh_keys.public_ssh_key
  name               = var.name
  ami                = var.ami
  instance_type      = var.instance_type
  private_ssh_key    = var.private_ssh_key
}

# Módulo de ECS (Cluster, Service, Task, Alarms, SNS, etc.)
module "ecs" {
  source = "./modules/ecs"

  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id
  region           = var.region
  name             = var.name
  sns_email        = var.sns_email
}

# Módulo de VPC Privada y Peering
module "private_network" {
  source = "./modules/private_network"

  vpc_ip              = var.vpc_ip
  instance_type       = var.instance_type
  ami                 = var.ami
  vpc_id              = module.network.vpc_id
  vpc_route_table_id  = module.network.vpc_route_table_id
  public_route_table  = module.network.public_route_table
  key_pair            = module.compute.key_pair
  private_vpc_cidr    = var.private_vpc_cidr
  private_subnet_cidr = var.private_subnet_cidr
  name                = var.name
}

# Modulo de la pagina web hosteada en S3
module "s3" {
  source = "./modules/s3"
  name   = var.name
}