# The one Application Terraform manages: the "root" app that points Argo CD at the
# GitOps repo's apps/ folder. Everything else (dev, prod) is defined in that repo.

resource "helm_release" "argocd_root_app" {
  name       = "argocd-root-app"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.6"
  namespace  = "argocd"

  values = [yamlencode({
    applications = {
      root = {
        namespace = "argocd"
        project   = "default"
        # Deleting root cascades to the env apps and their resources, so the ALBs
        # created by the Ingresses are removed before the VPC is destroyed.
        finalizers = ["resources-finalizer.argocd.argoproj.io"]
        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = "main"
          path           = "apps"
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = { prune = true, selfHeal = true }
        }
      }
    }
  })]

  # Argo Rollouts and Prometheus CRDs must exist before the apps sync Rollouts and ServiceMonitors
  depends_on = [helm_release.argocd, helm_release.argo_rollouts, helm_release.kube_prometheus_stack]
}
