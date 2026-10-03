# One-time bootstrap: the S3 bucket that holds the main stack's Terraform state.
# Uses local state (the bucket can't store its own state before it exists).
# Run once per AWS account; keep it when tearing down the main stack.

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67"
    }
  }
}

variable "region" {
  type    = string
  default = "il-central-1"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = "calculator", ManagedBy = "terraform", Stack = "bootstrap" }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tfstate" {
  # Account id keeps the name globally unique
  bucket = "calculator-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "init_command" {
  description = "Run this in infra/terraform to connect the main stack to the bucket"
  value       = "terraform init -backend-config=\"bucket=${aws_s3_bucket.tfstate.bucket}\""
}
