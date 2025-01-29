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
  default     = "nebo"
  description = "name that will be use on the resources"
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

variable "private_ssh_key" {
  type        = string
  description = "file that contains a private ssh key"
}