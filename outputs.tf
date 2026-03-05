output "instance_public_ip" {
    value = aws_instance.steam_server.public_ip
}

output "game_connection_info" {
    description = "Connection info for each game server"
    value = {
        for game_name, game in var.games : game_name => {
            address = var.domain_name
            ip      = aws_instance.steam_server.public_ip
            ports   = [for p in game.ports : "${p.host_port}/${p.protocol}"]
        }
    }
}
