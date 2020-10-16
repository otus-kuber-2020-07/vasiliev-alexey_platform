terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.00"

}
provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
}




resource "helm_release" "flagger" {

  name             = "flagger"
  chart            = "flagger"
  namespace        = "istio-system"
  repository       = "https://flagger.app"
  create_namespace = true


 depends_on = [
    kubernetes_manifest.customresourcedefinition_canaries_flagger_app,
    kubernetes_manifest.customresourcedefinition_metrictemplates_flagger_app,
    kubernetes_manifest.customresourcedefinition_alertproviders_flagger_app
    
  ]


  set {
    name  = "crd.create"
    value = false
  }

  set {
    name  = "meshProvider"
    value = "istio"
  }

  set {
    name  = "metricsServer"
    value = "http://prometheus:9090"
  }

}
