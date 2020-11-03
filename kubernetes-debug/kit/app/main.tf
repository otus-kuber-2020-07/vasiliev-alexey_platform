terraform {
  required_version = ">= 0.12.26"
}

provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
}

locals {
  default-namespace = "default"
}

# provider = kubernetes-alpha
# "namespace" = "${local.default-namespace}"

resource "kubernetes_manifest" "netperf_example" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "app.example.com/v1alpha1"

    "kind" = "Netperf"
    "metadata" = {
      "name"      = "example"
      "namespace" = "${local.default-namespace}"
    }
  }
}
