variable "aws_region" {
         default = "eu-west-2"
}

variable "vpc_cidr" {
         default = "10.10.0.0/16"
}
          
variable "subnets_cidr" {
          type = list
          default = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "azs" {
          type = list
          default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}        

variable "amiid" {
          default = "ami-033af134328c47f48"
}

variable "instance_type" {
          default = "t2.micro"
}

variable "number_instances" {
          default = 3
}

variable "key" {
          default = "NBG_webservers"
}
