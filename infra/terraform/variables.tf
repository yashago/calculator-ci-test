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
  description = <<-EOT
    Repo allowed to push images via GitHub OIDC, as it appears in the token's sub claim.
    This repo uses GitHub's immutable-ID format, owner@<owner id>/repo@<repo id>, which a
    deleted-and-recreated repo with the same name cannot match.
  EOT
  type        = string
  default     = "yashago@8012182/calculator-ci-test@1401694108"
}

variable "github_repo_id" {
  description = "Numeric ID of the repo above (GitHub API: GET /repos/yashago/calculator-ci-test → id)"
  type        = string
  default     = "1401694108"
}

variable "shared_workflow_refs" {
  description = "The reusable workflow allowed to publish, without the @ref suffix, in both claim spellings"
  type        = list(string)
  default = [
    "yashago/ci-workflows/.github/workflows/java-service.yml",
    "yashago@8012182/ci-workflows@1412800231/.github/workflows/java-service.yml",
  ]
}

variable "gitops_repo_url" {
  description = "Repo Argo CD syncs from (apps/ folder holds the environment Applications)"
  type        = string
  default     = "https://github.com/yashago/calculator-gitops.git"
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
