variable "public_subnet_id" {
  type        = string
  description = "IP of the publis subnet"
}

variable "sg_id" {
  type        = string
  description = "IP of the security group"
}

variable "ami" {
  type        = string
  description = "ami of the os that will be use on the instance"
}

variable "instance_type" {
  type        = string
  description = "instance type for the instance"
}

variable "name" {
  type        = string
  description = "name that will be use on the resources"
}

variable "key_pair" {
  type = string
}