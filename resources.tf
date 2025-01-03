# Create a key pair
resource "aws_key_pair" "deployer" {
    key_name   = var.key_name
    public_key = var.public_key
}

# Create a security group for the Steam server
resource "aws_security_group" "steam_server_sg" {
    name = "steam_server_sg"
    description = "Security group for the Steam server"
    vpc_id = aws_vpc.steam_server_vpc.id
    tags = {
        Name = "steam_server_sg"
    }
}

# Loop through the inbound_ports_map variable to create inbound rules
resource "aws_vpc_security_group_ingress_rule" "steam_server_ingress" {
    for_each = var.ingress_ports_map
    security_group_id = aws_security_group.steam_server_sg.id
    from_port = each.value.from_port
    to_port = each.value.to_port
    ip_protocol = each.value.protocol
    cidr_ipv4 = "0.0.0.0/0"
    tags = {
        Name = "steam_server_ingress-${each.key}"
    }
}

resource "aws_vpc_security_group_egress_rule" "steam_server_egress" {
    security_group_id = aws_security_group.steam_server_sg.id
    ip_protocol = "-1"
    cidr_ipv4 = "0.0.0.0/0"
    tags = {
        Name = "steam_server_egress"
    }
}

# Create an EC2 instance
resource "aws_instance" "steam_server" {
    ami = var.instance_ami
    instance_type = var.instance_type
    key_name = aws_key_pair.deployer.key_name
    subnet_id = aws_subnet.steam_server_subnet.id
    vpc_security_group_ids = [aws_security_group.steam_server_sg.id]
    tags = {
        Name = "steam_server"
    }
    associate_public_ip_address = true
}

# create A from Public IPv4 DNS to Route53 domain
resource "aws_route53_record" "steam_server" {
    zone_id = var.zone_id
    name    = var.domain_name
    type    = "A"
    ttl     = "300"
    records = [aws_instance.steam_server.public_ip]
}
