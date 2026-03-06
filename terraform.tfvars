# instance_type     = "t2.micro"
instance_type     = "c7a.4xlarge"
instance_ami      = "ami-0e2c8caa4b6378d8c"
key_name          = "my-key-pair"
public_key        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2kXSVe389PU4ULD7Mf/tRpILdtK4QyZf9JNreDnwpHooA+75UbMQBHNlzooUsjkRQ5yixcrecH/eJfzOHPICkGcrYF3ga0kaEr0zg7EWtbxov0f3EWEaXOG+KyGB4PQtDTzlpYAe99AHn/h+Mu+Ons9S3rMaLnuA9g+8UHP3080R8xk+BNv2KM2O+Yaipfpe5pV4m91RMCI4oSj/KfmB3+ldNP4X0u9wRamoZw6n3Kh/U4yyh2jlGgAFUi2+XLzS091iPWQN3SsrXU6bb5l/gqZ+DmydEwU5MraaS77Yxu0ehEnVowO1rPANzZhfmJS2HPeUEFt1G3L0nydfxlMKUB0PNa+mqh6zhFAqlv719AWSThb/xJB2I0vR7eU12iEYcizKj1h3Y/sinPU0oYL9az2XEBmo51CptiR/rjkw7OUNPc5Yh6Q4QkeTrbLJy7PMoGUJOu1gygGVY13GGG7JXjOXcNh0WAtiYJAmkhaWf3LjJPeqvy3kXrSpEvAXVhyc= teeth@DESKTOP-VSOVJ37"
zone_id           = "Z28HT7ZZCAX19E"
domain_name       = "steam.thirteenteeth.com"
vpc_cidr_block    = "172.16.0.0/16"
subnet_cidr_block = "172.16.10.0/24"
availability_zone = "us-east-1a"
games = {
  # valheim = {
  #   app_id       = "896660"
  #   docker_image = "cm2network/valheim"
  #   data_volume_size = 10
  #   env_vars = {
  #     SERVER_PORT     = "2456"
  #     SERVER_NAME     = "My Valheim Server"
  #   }
  #   volumes = [
  #     { name_suffix = "data", container_path = "/home/steam/valheim-dedicated" }
  #   ]
  #   ports = [
  #     { host_port = 2456, container_port = 2456, protocol = "udp" },
  #     { host_port = 2457, container_port = 2457, protocol = "udp" },
  #     { host_port = 2456, container_port = 2456, protocol = "tcp" },
  #     { host_port = 2457, container_port = 2457, protocol = "tcp" }
  #   ]
  # }
  # enshrouded = {
  #   app_id       = "2278520"
  #   docker_image = "sknnr/enshrouded-dedicated-server:latest"
  #   data_volume_size = 20
  #   env_vars = {
  #     SERVER_NAME     = "My Enshrouded Server"
  #     SERVER_SLOTS    = "16"
  #   }
  #   volumes = [
  #     { name_suffix = "data", container_path = "/home/steam/enshrouded/savegame" }
  #   ]
  #   ports = [
  #     { host_port = 15636, container_port = 15636, protocol = "udp" },
  #     { host_port = 15637, container_port = 15637, protocol = "udp" }
  #   ]
  # }
  vrising = {
    app_id           = "1829350"
    docker_image     = "trueosiris/vrising:latest"
    data_volume_size = 15
    entrypoint       = "/bin/bash"
    cmd_args         = "-c \"sed -i 's/\\r//g' /start.sh && exec /bin/bash /start.sh\""
    env_vars = {
      TZ         = "America/New_York"
      SERVERNAME = "My V Rising Server"
      WORLDNAME  = "world1"
      GAMEPORT   = "9876"
      QUERYPORT  = "9877"
      WINEDEBUG  = "fixme-all"
    }
    volumes = [
      { name_suffix = "server",         container_path = "/mnt/vrising/server",         backup = false },
      { name_suffix = "persistentdata", container_path = "/mnt/vrising/persistentdata", backup = true }
    ]
    ports = [
      { host_port = 9876, container_port = 9876, protocol = "udp" },
      { host_port = 9877, container_port = 9877, protocol = "udp" }
    ]
  }
  tf2 = {
    app_id           = "440"
    docker_image     = "cm2network/tf2:latest"
    data_volume_size = 10
    env_vars = {
      SRCDS_TOKEN      = "" # set in secrets.tfvars (gitignored)
      SRCDS_HOSTNAME   = "My TF2 Server"
      SRCDS_PORT       = "27015"
      SRCDS_TV_PORT    = "27020"
      SRCDS_MAXPLAYERS = "24"
      SRCDS_STARTMAP   = "ctf_2fort"
      SRCDS_TICKRATE   = "66"
      SRCDS_REGION     = "3"
    }
    volumes = [
      { name_suffix = "data", container_path = "/home/steam/tf-dedicated", backup = true }
    ]
    ports = [
      { host_port = 27015, container_port = 27015, protocol = "udp" },
      { host_port = 27015, container_port = 27015, protocol = "tcp" },
      { host_port = 27020, container_port = 27020, protocol = "udp" }
    ]
  }
}
