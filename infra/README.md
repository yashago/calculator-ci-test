# Infrastructure

Terraform for the calculator platform in `il-central-1`: VPC, EKS, ECR, the GitHub OIDC role
for CI, and the cluster add-ons (AWS Load Balancer Controller, Argo CD, Argo Rollouts,
kube-prometheus-stack).

| Directory | What | State |
|---|---|---|
| `bootstrap/` | S3 bucket for Terraform state | local, run once per account |
| `terraform/` | everything else | S3 (`calculator/terraform.tfstate`) |

**Cost:** about $0.25–0.30/hour while up (EKS control plane, 2× t3.medium, NAT gateway).
Destroy after each session.

## Prerequisites

- Terraform ≥ 1.10, AWS CLI v2, kubectl, Helm
- `aws configure` (or `aws configure sso`) with an admin-level identity
- `aws sts get-caller-identity` shows the intended account

## First-time setup

```sh
# 1. State bucket (once)
cd infra/bootstrap
terraform init
terraform apply                         # prints init_command

# 2. Main stack
cd ../terraform
cp terraform.tfvars.example terraform.tfvars   # set admin_cidrs to your IP/32
terraform init -backend-config="bucket=<state_bucket from step 1>"
terraform apply                         # ~15–20 minutes

# 3. Connect kubectl
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

Then in GitHub → Settings → Secrets and variables → Actions → **Variables**:

| Variable | Value |
|---|---|
| `AWS_ROLE_ARN` | `terraform output -raw github_ci_role_arn` |
| `AWS_REGION` | `il-central-1` |

The next push to `main` publishes the image to ECR and signs it.

## Day to day

```sh
# Argo CD UI → https://localhost:8080 (user: admin)
kubectl -n argocd port-forward svc/argocd-server 8080:443
$(terraform output -raw argocd_password_command)

# Your IP changed → update admin_cidrs in terraform.tfvars, then
terraform apply
```

## Teardown

```sh
cd infra/terraform
terraform destroy
```

Leave the `bootstrap/` bucket in place (it costs cents) so the next `apply` reuses it.
While the stack is down, CI's `publish` job fails because the role no longer exists;
delete the `AWS_ROLE_ARN` variable to skip it until the next apply.
