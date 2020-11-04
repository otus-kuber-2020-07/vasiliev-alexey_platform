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
# "namespace" = "${locals.default-namespace}"