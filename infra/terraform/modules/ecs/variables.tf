variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "public_subnet_id" {
  type        = string
  description = "ID of the public subnet"
}

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

variable "sns_email" {
  type        = string
  description = "alerts email receiver"
}
