instance_type = "t2.micro"
instance_ami = "ami-0e2c8caa4b6378d8c"
key_name = "my-key-pair"
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2kXSVe389PU4ULD7Mf/tRpILdtK4QyZf9JNreDnwpHooA+75UbMQBHNlzooUsjkRQ5yixcrecH/eJfzOHPICkGcrYF3ga0kaEr0zg7EWtbxov0f3EWEaXOG+KyGB4PQtDTzlpYAe99AHn/h+Mu+Ons9S3rMaLnuA9g+8UHP3080R8xk+BNv2KM2O+Yaipfpe5pV4m91RMCI4oSj/KfmB3+ldNP4X0u9wRamoZw6n3Kh/U4yyh2jlGgAFUi2+XLzS091iPWQN3SsrXU6bb5l/gqZ+DmydEwU5MraaS77Yxu0ehEnVowO1rPANzZhfmJS2HPeUEFt1G3L0nydfxlMKUB0PNa+mqh6zhFAqlv719AWSThb/xJB2I0vR7eU12iEYcizKj1h3Y/sinPU0oYL9az2XEBmo51CptiR/rjkw7OUNPc5Yh6Q4QkeTrbLJy7PMoGUJOu1gygGVY13GGG7JXjOXcNh0WAtiYJAmkhaWf3LjJPeqvy3kXrSpEvAXVhyc= teeth@DESKTOP-VSOVJ37"
zone_id = "Z28HT7ZZCAX19E"
domain_name = "steam.thirteenteeth.com"
vpc_cidr_block = "172.16.0.0/16"
subnet_cidr_block = "172.16.10.0/24"
availability_zone = "us-east-1a"
ingress_ports_map = {
    inbound-ssh-tcp = {
        from_port = 22
        to_port = 22
        protocol = "tcp"
    }
    inbound-steam-udp = {
        from_port = 27015
        to_port = 27016
        protocol = "udp"
    }
    inbound-steam-tcp = {
        from_port = 27015
        to_port = 27016
        protocol = "tcp"
    }
}
