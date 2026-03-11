variable "instance_type" {
  description = "EC2 instance type - recommend at least t3.xlarge for multiple games"
  type        = string
  default     = "t3.xlarge"

  validation {
    condition     = !contains(["t2.micro", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Instance type is too small for running multiple game servers. Use at least t3.medium."
  }
}

variable "instance_ami" {
  description = "The AMI to use for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for the EC2 instance"
  type        = string
}

variable "public_key" {
  description = "The public key to use for the key pair"
  type        = string
}

variable "zone_id" {
  description = "The Route53 zone ID"
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for the Steam server"
  type        = string
}

variable "games" {
  description = "Map of game server configurations"
  type = map(object({
    app_id       = string
    docker_image = string
    env_vars     = map(string)
    ports = list(object({
      host_port      = number
      container_port = number
      protocol       = string
    }))
    volumes = list(object({
      name_suffix    = string
      container_path = string
      backup         = optional(bool, true)
    }))
    entrypoint       = optional(string, "")
    cmd_args         = optional(string, "")
    data_volume_size = optional(number, 20)
  }))
  default = {}
}

variable "game_secrets" {
  description = "Per-game secret env vars (e.g. tokens, passwords) merged over game env_vars at apply time. Store in secrets.tfvars and keep out of git."
  type        = map(map(string))
  sensitive   = true
  default     = {}
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string
}

variable "availability_zone" {
  description = "The availability zone for the subnet"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}
