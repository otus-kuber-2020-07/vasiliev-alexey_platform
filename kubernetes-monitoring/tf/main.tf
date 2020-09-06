terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.00"

}


resource "helm_release" "nginx" {
  # для миникуба отключим - там через  addon
  count            = var.is_minikube ? 0 : 1
  name             = "nginx"
  chart            = "./helm/nginx"
  namespace        = "nginx-ingress"
  create_namespace = true

}


resource "helm_release" "prometheus" {
  name             = "prometheus"
  chart            = "./helm/prometheus"
  namespace        = "monitoring"
  create_namespace = true
  depends_on = [
    helm_release.nginx
  ]
}


resource "helm_release" "nginx-app" {

  name             = "nginx-app"
  chart            = "nginx"
  repository       = "https://charts.bitnami.com/bitnami"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "replicaCount"
    value = "3"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }
}



resource "helm_release" "grafana" {
  name             = "grafana"
  chart            = "./helm/grafana"
  namespace        = "monitoring"
  create_namespace = true

 depends_on = [
    helm_release.nginx
  ]

}
