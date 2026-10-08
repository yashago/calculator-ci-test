module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = var.name
  cidr = "10.0.0.0/16"
  azs  = local.azs

  private_subnets = [for i, _ in local.azs : cidrsubnet("10.0.0.0/16", 4, i)]      # nodes and pods
  public_subnets  = [for i, _ in local.azs : cidrsubnet("10.0.0.0/16", 8, 48 + i)] # ALB and NAT

  enable_nat_gateway = true
  single_nat_gateway = true # one NAT instead of one per AZ: cheaper, fine for a demo

  # Tells the AWS Load Balancer Controller where to place ALBs
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
}
