variable "region" {
  type    = string
  default = "il-central-1"
}

variable "name" {
  description = "Prefix for all resources"
  type        = string
  default     = "calculator"
}

variable "github_repo" {
  description = "owner/repo allowed to push images via GitHub OIDC"
  type        = string
  default     = "yashago/calculator-ci-test"
}

variable "kubernetes_version" {
  type    = string
  default = "1.37"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "admin_cidrs" {
  description = <<-EOT
    CIDRs allowed to reach the EKS API (kubectl/helm), e.g. ["203.0.113.7/32"].
    CI never needs the API: Argo CD pulls from Git inside the cluster.
  EOT
  type        = list(string)
}
