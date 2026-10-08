# Accepted risks (review by the expiry date):
# AWS-0040 public API endpoint: restricted to admin_cidrs; fully private needs a VPN or bastion.
# AWS-0104 unrestricted node egress: nodes pull images from ECR/Docker Hub/quay.io and call
#          AWS APIs and GitHub; locking it down needs VPC endpoints plus an egress proxy.
#trivy:ignore:AWS-0040:exp:2027-04-01
#trivy:ignore:AWS-0104:exp:2027-04-01
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.26"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.admin_cidrs

  # Whoever runs terraform apply gets cluster-admin
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  addons = {
    coredns                = {}
    kube-proxy             = {}
    eks-pod-identity-agent = { before_compute = true }
    vpc-cni = {
      before_compute = true
      # Prefix delegation raises the pod limit of a t3.medium from 17 to 110
      configuration_values = jsonencode({
        env = { ENABLE_PREFIX_DELEGATION = "true", WARM_PREFIX_TARGET = "1" }
      })
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.node_instance_type]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
    }
  }
}
