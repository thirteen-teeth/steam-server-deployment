variable "instance_type" {
    description = "The type of EC2 instance to launch"
    type = string
}

variable "instance_ami" {
    description = "The AMI to use for the EC2 instance"
    type = string
}

variable "key_name" {
    description = "The name of the key pair to use for the EC2 instance"
    type = string
}

variable "public_key" {
    description = "The public key to use for the key pair"
    type = string
}

variable "zone_id" {
    description = "The Route53 zone ID"
    type = string
}

variable "domain_name" {
    description = "The domain name to use for the Steam server"
    type = string
}

variable "ingress_ports_map" {
    description = "Map of inbound ports to open"
    type = map
}

variable "subnet_cidr_block" {
    description = "The CIDR block for the subnet"
    type = string
}

variable "availability_zone" {
    description = "The availability zone for the subnet"
    type = string
}

variable "vpc_cidr_block" {
    description = "The CIDR block for the VPC"
    type = string  
}
