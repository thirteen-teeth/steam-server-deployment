.PHONY: setup lint validate plan apply destroy ssh backup restore help

TFVARS_FILE  := terraform.tfvars
SECRETS_FILE := secrets.tfvars
SSH_KEY      := ~/.ssh/my-key-pair
SSH_USER     := ubuntu
SSH_HOST     := steam.thirteenteeth.com

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  setup     Install terraform and tflint"
	@echo "  lint      Run tflint"
	@echo "  validate  Run terraform validate"
	@echo "  check     Run lint and validate"
	@echo "  plan      Run terraform plan"
	@echo "  apply     Run terraform apply"
	@echo "  destroy   Run terraform destroy"
	@echo "  ssh       Clear known_hosts entry and SSH into the server"
	@echo "  backup    Rsync all game volumes to ~/backups/steam-servers"
	@echo "  restore   Restore game volumes from a local backup (see restore-games.sh)"

setup:
	@echo "==> Installing tflint..."
	curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
	@echo "==> Initialising Terraform..."
	terraform init

lint:
	@echo "==> Running tflint..."
	tflint --init
	tflint

validate:
	@echo "==> Running terraform validate..."
	terraform validate

check: lint validate
	@echo "==> All checks passed."

plan:
	terraform plan -var-file="$(TFVARS_FILE)" -var-file="$(SECRETS_FILE)"

apply:
	terraform apply -var-file="$(TFVARS_FILE)" -var-file="$(SECRETS_FILE)"

destroy:
	terraform destroy -var-file="$(TFVARS_FILE)" -var-file="$(SECRETS_FILE)"

ssh:
	@echo "==> Removing known_hosts entry for $(SSH_HOST)..."
	ssh-keygen -f "$$HOME/.ssh/known_hosts" -R "$(SSH_HOST)"
	@echo "==> Connecting to $(SSH_HOST)..."
	ssh -i "$(SSH_KEY)" $(SSH_USER)@$(SSH_HOST)

backup:
	SSH_KEY="$(SSH_KEY)" REMOTE_USER="$(SSH_USER)" REMOTE_HOST="$(SSH_HOST)" bash backup-games.sh

restore:
	SSH_KEY="$(SSH_KEY)" REMOTE_USER="$(SSH_USER)" REMOTE_HOST="$(SSH_HOST)" bash restore-games.sh
