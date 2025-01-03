# create VPC
resource "aws_vpc" "steam_server_vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "steam_server_vpc"
    }
}

# Create a subnet
resource "aws_subnet" "steam_server_subnet" {
    vpc_id = aws_vpc.steam_server_vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.availability_zone
    tags = {
        Name = "steam_server_subnet"
    }
}

# create internet gateway
resource "aws_internet_gateway" "steam_server_igw" {
    vpc_id = aws_vpc.steam_server_vpc.id
    tags = {
        Name = "steam_server_igw"
    }
}

# create route table
resource "aws_route_table" "steam_server_route_table" {
    vpc_id = aws_vpc.steam_server_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.steam_server_igw.id
    }
    tags = {
        Name = "steam_server_route_table"
    }
}

# associate route table with subnet
resource "aws_route_table_association" "steam_server_route_table_association" {
    subnet_id = aws_subnet.steam_server_subnet.id
    route_table_id = aws_route_table.steam_server_route_table.id
}
