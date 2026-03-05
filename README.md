# Steam Server Deployment

## Table of Contents

- [AWS Account Bootstrap & IAM Setup](#aws-account-bootstrap--iam-setup)
- [Game Server Reference Commands](#game-server-reference-commands)

---

## AWS Account Bootstrap & IAM Setup

This guide walks through securing a brand new AWS account, creating an IAM super-user, and configuring local credentials so Terraform can provision all project resources (EC2, VPC, Route 53) in `us-east-1`.

---

### Phase 1 — Secure the Root Account

1. Sign in to [console.aws.amazon.com](https://console.aws.amazon.com) with your root email and password.

2. Click your account name (top-right) → **Security credentials**.

3. Under **Multi-factor authentication (MFA)**, click **Assign MFA device** → choose **Authenticator app** (Google Authenticator, Authy, etc.) and complete the setup wizard.
   > Root MFA is mandatory before doing anything else. Do not skip this step.

4. Under **Access keys**, confirm there are **no root access keys**. If any exist, delete them immediately. Root credentials should never be used programmatically.

5. Set a human-readable account alias:
   - Navigate to **IAM** → **Dashboard** → **Create alias** (e.g. `thirteenteeth`)
   - This changes your sign-in URL to `https://thirteenteeth.signin.aws.amazon.com/console`

---

### Phase 2 — Create the IAM Super-User

6. Navigate to **IAM** → **Users** → **Create user**.

7. Set a username (e.g. `terraform-admin`). Enabling console access is optional — for a Terraform-only workflow it is not required.

8. On the **Permissions** step:
   - Choose **Attach policies directly**
   - Search for and select **AdministratorAccess**
   - This covers all resources in this project: EC2, VPC, Key Pairs, Security Groups, EBS volumes, and Route 53

9. Skip tags (optional), review the summary, and click **Create user**.

---

### Phase 3 — Generate Access Keys

10. Open the newly created user → **Security credentials** tab → **Create access key**.

11. Select use case: **Command Line Interface (CLI)** → acknowledge the recommendation → **Next** → **Create access key**.

12. **Immediately copy or download the `.csv` file.** The secret access key is only shown once and cannot be retrieved afterward.

---

### Phase 4 — Configure Local AWS Credentials

13. Verify the AWS CLI is installed:
    ```bash
    aws --version
    ```
    If not installed, follow the [official install guide](https://aws.amazon.com/cli/).

14. Configure credentials using the keys from step 12:
    ```bash
    aws configure
    ```
    Enter the following when prompted:

    | Prompt | Value |
    |---|---|
    | AWS Access Key ID | from step 12 |
    | AWS Secret Access Key | from step 12 |
    | Default region name | `us-east-1` |
    | Default output format | `json` |

15. Verify the credentials are working:
    ```bash
    aws sts get-caller-identity
    ```
    Expected output — your account ID and IAM user ARN:
    ```json
    {
        "UserId": "AIDA...",
        "Account": "123456789012",
        "Arn": "arn:aws:iam::123456789012:user/terraform-admin"
    }
    ```

---

### Phase 5 — Pre-Flight Checks Before `terraform apply`

16. **Route 53 Hosted Zone** — `terraform.tfvars` references a `zone_id`. Confirm this hosted zone exists in your new account:
    - Route 53 → **Hosted zones**
    - If it does not exist, create it: **Create hosted zone** → enter your domain name → type **Public hosted zone**
    - Update `zone_id` in `terraform.tfvars` with the new zone ID

17. **AMI Availability** — The project uses a Ubuntu 24.04 LTS AMI in `us-east-1`. Confirm it is accessible:
    ```bash
    aws ec2 describe-images --image-ids $(grep instance_ami terraform.tfvars | awk -F'"' '{print $2}') --region us-east-1
    ```

18. **EC2 vCPU Quota** — The project uses `c7a.4xlarge` which requires **16 vCPUs**. New AWS accounts often have a default limit of 0 for compute-optimized instances.
    - Check your current limit: EC2 console → **Limits** → search `Running On-Demand C instances`
    - If the limit is below 16, submit a quota increase request before running `apply` (approval usually takes minutes to a few hours)

---

### Phase 6 — Run Terraform

19. From the project root, initialize the provider:
    ```bash
    terraform init
    ```
    This downloads the `hashicorp/aws ~> 4.0` provider.

20. Preview the changes:
    ```bash
    terraform plan
    ```
    Expect **11 resources to add**: VPC, subnet, internet gateway, route table, route table association, key pair, security group, ingress rules, egress rule, EC2 instance, and Route 53 A record.

21. Apply the infrastructure:
    ```bash
    terraform apply
    ```
    Type `yes` when prompted. Provisioning typically takes 1–3 minutes.

---

### Verification

After `terraform apply` completes, run the following checks:

```bash
# Confirm the instance public IP was output
terraform output instance_public_ip

# Confirm the Route 53 record resolves (replace with your domain)
dig steam.thirteenteeth.com

# SSH into the server (replace with your private key path)
ssh -i ~/.ssh/my-key-pair ubuntu@steam.thirteenteeth.com
```

---

### Teardown

To destroy all provisioned resources:

```bash
terraform destroy
```

> **Note:** This will terminate the EC2 instance and delete all associated resources. Ensure any game saves are backed up first (see `backup-enshrouded-save.sh`).

---

## Game Server Reference Commands

### Valheim

```bash
# https://developer.valvesoftware.com/wiki/SteamCMD
# https://hub.docker.com/r/cm2network/valheim/

docker stop valheim-dedicated; docker rm valheim-dedicated
mkdir /opt/valheim-data
chmod 777 /opt/valheim-data
docker run -d --net=host -v "/opt/valheim-data:/home/steam/valheim-dedicated/" -e SERVER_PORT=2456 --name=valheim-dedicated cm2network/valheim
```

### SteamCMD (Enshrouded install)

```bash
docker stop steamcmd; docker rm steamcmd
docker run -it --name=steamcmd cm2network/steamcmd bash
./steamcmd.sh +force_install_dir /home/steam/enshrouded-dedicated +login anonymous +app_update 2278520 +quit
```

### Enshrouded

```bash
docker volume create enshrouded-persistent-data
docker run \
  --detach \
  --name enshrouded-server \
  --mount type=volume,source=enshrouded-persistent-data,target=/home/steam/enshrouded/savegame \
  --publish 15636:15636/udp \
  --publish 15637:15637/udp \
  --env=SERVER_NAME='Enshrouded Containerized Server' \
  --env=SERVER_SLOTS=16 \
  --env=SERVER_PASSWORD='boobs' \
  --env=GAME_PORT=15636 \
  --env=QUERY_PORT=15637 \
  sknnr/enshrouded-dedicated-server:latest
```
