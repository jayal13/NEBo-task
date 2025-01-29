variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "public_subnet_id" {
  type        = string
  description = "ID of the public subnet"
}

variable "my_ip" {
  type = string
}

variable "public_ssh_key" {
  type        = string
  description = "public ssh key that will be use by the instances"
}

variable "name" {
  type        = string
  description = "name that will be use on the resources"
}

variable "ami" {
  type        = string
  description = "ami of the os that will be use on the instance"
}

variable "instance_type" {
  type        = string
  description = "instance type for the instance"
}

variable "private_ssh_key" {
  type        = string
  description = "file that contains a private ssh key"
}

variable "key_pair" {
  type = string
}

variable "public_route_table" {
  type = string
}