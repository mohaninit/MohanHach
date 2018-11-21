variable "vpc_name" {
  description = "vpc name"
  default = "main"
}

variable "aws_region" {
  description = "aws region"
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "cidr"
  default = "10.0.0.0/16"

}
  
variable "vpc_instance_tenancy" {
  description = "instance tenancy"
  default = "dedicated"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "10.0.2.0/24"
}

variable "public_route_cidr" {
  description = "CIDR for the Public Route"
  default = "0.0.0.0/0"
}

variable "public_sg_cidr" {
  description = " CIDR for the Public Security Group"
  default = "0.0.0.0/0"
}

variable "private_sg_cidr" {
  description = " CIDR for the private Security Group"
  default = "10.0.0.0/16"
}

variable "amis" {
  description = "aws instance ami-id "
  default = "ami-059eeca93cf09eebd"
}

variable "aws_key_name" {
  description = " aws instance ssh-key"
  default = "work-kp-01"
}


