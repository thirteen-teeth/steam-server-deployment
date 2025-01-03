# Create a key pair
resource "aws_key_pair" "deployer" {
    key_name   = var.key_name
    public_key = var.public_key
}

# Create an EC2 instance
resource "aws_instance" "steam_server" {
    ami           = var.instance_ami
    instance_type = var.instance_type
    key_name      = aws_key_pair.deployer.key_name
    vpc_security_group_ids = [aws_security_group.steam_server_sg.id]
}

# Create a security group for the Steam server
resource "aws_security_group" "steam_server_sg" {
    name = "steam_server_sg"
    description = "Security group for the Steam server"
    ingress {
        description = "Allow SSH traffic"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "Allow Steam server traffic"
        from_port   = 2456
        to_port     = 2456
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "Allow Steam server traffic"
        from_port   = 2457
        to_port     = 2457
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# create A from Public IPv4 DNS to Route53 domain
resource "aws_route53_record" "steam_server" {
    zone_id = var.zone_id
    name    = var.domain_name
    type    = "A"
    ttl     = "300"
    records = [aws_instance.steam_server.public_ip]
}
