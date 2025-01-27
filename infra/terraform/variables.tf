variable "region" {
  type        = string
  default     = "us-west-1"
  description = "region of aws that will be use in the project"
}

variable "name" {
  type        = string
  default     = "nebo"
  description = "name that will be use on the resources"
}

variable "vpc_ip" {
  type        = string
  default     = "10.0.0.0/16"
  description = "IP that will be use for the VPC"
}

variable "private_subnet_ip" {
  type        = string
  default     = "10.0.128.0/17"
  description = "IP that will be use for the private subnet"
}

variable "public_subnet_ip" {
  type        = string
  default     = "10.0.0.0/17"
  description = "IP that will be use for the public subnet"
}

variable "route_table_ips" {
  type        = list(string)
  description = "List of routes for the route table"
}

variable "public_ssh_key" {
  type        = string
  description = "file that contains a public ssh key"
}

variable "private_ssh_key" {
  type        = string
  description = "file that contains a private ssh key"
}

variable "ami" {
  type        = string
  default     = "ami-07d2649d67dbe8900"
  description = "ami of the os that will be use on the instance"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "instance type for the instance"
}

variable "ebs_size" {
  type        = number
  default     = 2
  description = "size in GB of the ebs"
}

variable "sns_email" {
  type = string
  description = "alerts email receiver"
}