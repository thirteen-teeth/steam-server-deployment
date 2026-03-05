locals {
    # Flatten all ports across all games into a map keyed by a unique string
    all_game_ports_map = {
        for item in flatten([
            for game_name, game in var.games : [
                for port in game.ports : {
                    key       = "${game_name}-${port.host_port}-${port.protocol}"
                    from_port = port.host_port
                    to_port   = port.host_port
                    protocol  = port.protocol
                }
            ]
        ]) : item.key => item
    }

    # Build docker run commands for each game
    game_run_commands = join("\n\n", [
        for game_name, game in var.games : join(" \\\n  ", concat(
            ["# --- ${game_name} ---\n${join("\n", [for v in game.volumes : "docker volume create ${game_name}-${v.name_suffix}"])}\ndocker run"],
            ["--detach"],
            ["--restart unless-stopped"],
            ["--name ${game_name}-server"],
            [for v in game.volumes : "--mount type=volume,source=${game_name}-${v.name_suffix},target=${v.container_path}"],
            [for port in game.ports : "--publish ${port.host_port}:${port.container_port}/${port.protocol}"],
            [for k, v in game.env_vars : "--env ${k}='${v}'"],
            game.entrypoint != "" ? ["--entrypoint \"${game.entrypoint}\""] : [],
            [game.docker_image],
            game.cmd_args != "" ? [game.cmd_args] : []
        ))
    ])

    user_data = join("\n\n", [
        file("install-docker.sh"),
        local.game_run_commands
    ])
}

# Create a key pair
resource "aws_key_pair" "deployer" {
    key_name   = var.key_name
    public_key = var.public_key
}

# Create a security group for the Steam server
resource "aws_security_group" "steam_server_sg" {
    name        = "steam_server_sg"
    description = "Security group for the Steam server"
    vpc_id      = aws_vpc.steam_server_vpc.id
    tags = {
        Name  = "steam_server_sg"
        Games = join(",", keys(var.games))
    }
}

# SSH ingress rule
resource "aws_vpc_security_group_ingress_rule" "ssh" {
    security_group_id = aws_security_group.steam_server_sg.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 22
    to_port           = 22
    ip_protocol       = "tcp"
    tags = {
        Name = "steam_server_ingress-ssh"
    }
}

# Game port ingress rules - one per unique game port
resource "aws_vpc_security_group_ingress_rule" "game_ports" {
    for_each = local.all_game_ports_map

    security_group_id = aws_security_group.steam_server_sg.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = each.value.from_port
    to_port           = each.value.to_port
    ip_protocol       = each.value.protocol
    tags = {
        Name = "steam_server_ingress-${each.key}"
    }
}

resource "aws_vpc_security_group_egress_rule" "steam_server_egress" {
    security_group_id = aws_security_group.steam_server_sg.id
    ip_protocol       = "-1"
    cidr_ipv4         = "0.0.0.0/0"
    tags = {
        Name = "steam_server_egress"
    }
}

resource "aws_instance" "steam_server" {
    ami                         = var.instance_ami
    instance_type               = var.instance_type
    key_name                    = aws_key_pair.deployer.key_name
    subnet_id                   = aws_subnet.steam_server_subnet.id
    vpc_security_group_ids      = [aws_security_group.steam_server_sg.id]
    associate_public_ip_address = true
    user_data                   = local.user_data
    user_data_replace_on_change = true
    tags = {
        Name  = "steam_server"
        Games = join(",", keys(var.games))
    }
    root_block_device {
        volume_size = 128
        volume_type = "gp3"
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
