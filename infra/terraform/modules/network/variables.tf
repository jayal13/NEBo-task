variable "region" {
  type        = string
  description = "region of aws that will be use in the project"
}

variable "vpc_ip" {
  type        = string
  description = "IP that will be use for the VPC"
}

variable "private_subnet_ip" {
  type        = string
  description = "IP that will be use for the private subnet"
}

variable "public_subnet_ip" {
  type        = string
  description = "IP that will be use for the public subnet"
}

variable "route_table_ips" {
  type        = list(string)
  description = "List of routes for the route table"
}

variable "name" {
  type        = string
  description = "name that will be use on the resources"
}

variable "my_ip" {
  type = string
}