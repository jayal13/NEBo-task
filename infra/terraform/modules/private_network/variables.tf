variable "private_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "name" {
  type        = string
  default     = "nebo"
  description = "name that will be use on the resources"
}

variable "vpc_ip" {
  type        = string
  description = "IP that will be use for the VPC"
}

variable "key_pair" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "instance_type" {
  type        = string
  description = "instance type for the instance"
}

variable "ami" {
  type        = string
  description = "ami of the os that will be use on the instance"
}

variable "vpc_route_table_id" {
  type = string
}

variable "public_route_table" {
  type = string
}