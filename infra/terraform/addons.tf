# Cluster add-ons installed with Helm. Chart versions are pinned; bump deliberately.

# ---- AWS Load Balancer Controller: turns Ingress objects into ALBs ----
module "aws_lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  name                            = "${var.name}-aws-lbc"
  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.5.0"
  namespace  = "kube-system"

  values = [yamlencode({
    clusterName    = module.eks.cluster_name
    region         = var.region
    vpcId          = module.vpc.vpc_id
    serviceAccount = { name = "aws-load-balancer-controller" }
  })]

  depends_on = [module.eks, module.aws_lb_controller_pod_identity]
}

# The controller registers a webhook for Services; install the rest after it is ready,
# or their Services fail admission.

# ---- Argo CD: syncs the GitOps repo into the cluster ----
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.9.6"
  namespace        = "argocd"
  create_namespace = true

  values = [yamlencode({
    dex           = { enabled = false } # local admin login only
    notifications = { enabled = false }
    server        = { service = { type = "ClusterIP" } } # reach via kubectl port-forward
  })]

  depends_on = [helm_release.aws_lb_controller]
}

# ---- Argo Rollouts: canary deployments with metric analysis ----
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  version          = "2.43.5"
  namespace        = "argo-rollouts"
  create_namespace = true

  values = [yamlencode({
    dashboard = { enabled = true }
  })]

  depends_on = [helm_release.aws_lb_controller]
}

# ---- Prometheus: metrics source for canary analysis ----
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "91.9.0"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600

  values = [yamlencode({
    alertmanager = { enabled = false }
    grafana      = { enabled = true }
    prometheus = {
      prometheusSpec = {
        retention = "2d"
        # Pick up ServiceMonitors from every namespace, not only this release's
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        resources = {
          requests = { cpu = "200m", memory = "512Mi" }
          limits   = { memory = "1Gi" }
        }
      }
    }
  })]

  depends_on = [helm_release.aws_lb_controller]
}
