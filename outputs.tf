output "instance_id" {
  description = "EC2 instance ID - used by Makefile stop-server / start-server targets"
  value       = aws_instance.steam_server.id
}

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

output "backup_config" {
  description = "Game backup configuration consumed by backup-games.sh and restore-games.sh"
  value = {
    for game_name, game in var.games : game_name => {
      container = "${game_name}-server"
      volumes = [
        for v in game.volumes : "${game_name}-${v.name_suffix}"
        if v.backup
      ]
    }
  }
}
