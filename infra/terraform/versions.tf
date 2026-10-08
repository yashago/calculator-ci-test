terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3"
    }
  }

  # Bucket is passed at init time (it contains the account id):
  #   terraform init -backend-config="bucket=<state_bucket output of infra/bootstrap>"
  backend "s3" {
    key          = "calculator/terraform.tfstate"
    region       = "il-central-1"
    encrypt      = true
    use_lockfile = true # S3-native locking, no DynamoDB table needed
  }
}
