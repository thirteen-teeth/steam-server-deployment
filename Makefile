.PHONY: setup lint validate plan apply destroy ssh backup restore stop-server start-server vrising-settings-init vrising-settings-upload help

TFVARS_FILE  := terraform.tfvars
SECRETS_FILE := secrets.tfvars
SSH_KEY      := ~/.ssh/my-key-pair
SSH_USER     := ubuntu
SSH_HOST     := steam.thirteenteeth.com
AWS_REGION   := us-east-1

help:
	@printf "\n"
	@printf "Steam Server Deployment\n"
	@printf "=======================\n"
	@printf "Usage: make <target>\n\n"
	@printf "Terraform\n"
	@printf "  %-24s %s\n" "setup" "Install tflint and run terraform init"
	@printf "  %-24s %s\n" "lint" "Run tflint"
	@printf "  %-24s %s\n" "validate" "Run terraform validate"
	@printf "  %-24s %s\n" "check" "Run lint and validate"
	@printf "  %-24s %s\n" "plan" "Run terraform plan"
	@printf "  %-24s %s\n" "apply" "Run terraform apply"
	@printf "  %-24s %s\n\n" "destroy" "Run terraform destroy"
	@printf "Operations\n"
	@printf "  %-24s %s\n" "ssh" "Refresh known_hosts entry and SSH in"
	@printf "  %-24s %s\n" "backup" "Rsync game volumes to ~/backups/steam-servers"
	@printf "  %-24s %s\n" "restore" "Restore game volumes from a local backup"
	@printf "  %-24s %s\n" "stop-server" "Stop EC2 instance (data is preserved)"
	@printf "  %-24s %s\n\n" "start-server" "Start the EC2 instance again"
	@printf "V Rising\n"
	@printf "  %-24s %s\n" "vrising-settings-init" "Extract default V Rising settings files locally"
	@printf "  %-24s %s\n" "vrising-settings-upload" "Upload V Rising settings files and restart"

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

stop-server:
	$(eval INSTANCE_ID := $(shell terraform output -raw instance_id))
	@echo "==> Stopping instance $(INSTANCE_ID)..."
	aws ec2 stop-instances --region $(AWS_REGION) --instance-ids $(INSTANCE_ID)
	@echo "==> Waiting for instance to stop..."
	aws ec2 wait instance-stopped --region $(AWS_REGION) --instance-ids $(INSTANCE_ID)
	@echo "==> Instance stopped. Note: the Elastic IP / Route53 record remain intact."

start-server:
	$(eval INSTANCE_ID := $(shell terraform output -raw instance_id))
	@echo "==> Starting instance $(INSTANCE_ID)..."
	aws ec2 start-instances --region $(AWS_REGION) --instance-ids $(INSTANCE_ID)
	@echo "==> Waiting for instance to be running..."
	aws ec2 wait instance-running --region $(AWS_REGION) --instance-ids $(INSTANCE_ID)
	@echo "==> Instance running. Waiting for status checks..."
	aws ec2 wait instance-status-ok --region $(AWS_REGION) --instance-ids $(INSTANCE_ID)
	@echo "==> Ready. Connect with: make ssh"

vrising-settings-init:
	bash vrising-settings-init.sh

vrising-settings-upload:
	SSH_KEY="$(SSH_KEY)" REMOTE_USER="$(SSH_USER)" REMOTE_HOST="$(SSH_HOST)" bash upload-vrising-settings.sh
