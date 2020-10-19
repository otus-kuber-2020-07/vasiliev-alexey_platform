terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.00"
}



provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
}


resource "helm_release" "vault" {
  name             = "vault"
  chart            = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  create_namespace = true

  depends_on = [
    helm_release.consul
  ]

  values = [<<EOF
server:
  standalone:
    enabled: false
  ha:
    enabled: true
ui:
  enabled: true

EOF
  ]

}

resource "helm_release" "consul" {
  name             = "consul"
  chart            = "consul"
  repository       = "https://helm.releases.hashicorp.com"
  create_namespace = true
}

