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

resource "kubernetes_manifest" "crd_netperfs_app_example_com" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "apiextensions.k8s.io/v1beta1"
    "kind"       = "CustomResourceDefinition"
    "metadata" = {
      "name"      = "netperfs.app.example.com"
      "namespace" = "${local.default-namespace}"
    }
    "spec" = {
      "group" = "app.example.com"
      "names" = {
        "kind"     = "Netperf"
        "listKind" = "NetperfList"
        "plural"   = "netperfs"
        "singular" = "netperf"
      }
      "scope"   = "Namespaced"
      "version" = "v1alpha1"
    }
  }
}


resource "kubernetes_manifest" "role_netperf_operator" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1beta1"
    "kind"       = "Role"
    "metadata" = {
      "name"      = "netperf-operator"
      "namespace" = "${local.default-namespace}"
    }
    "rules" = [
      {
        "apiGroups" = [
          "app.example.com",
        ]
        "resources" = [
          "*",
        ]
        "verbs" = [
          "*",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "pods",
          "pods/log",
        ]
        "verbs" = [
          "*",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "rolebinding_default_account_netperf_operator" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1beta1"
    "kind"       = "RoleBinding"
    "metadata" = {
      "name"      = "default-account-netperf-operator"
      "namespace" = "${local.default-namespace}"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "Role"
      "name"     = "netperf-operator"
    }
    "subjects" = [
      {
        "kind" = "ServiceAccount"
        "name" = "default"
      },
    ]
  }
}


resource "kubernetes_manifest" "deployment_netperf_operator" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata" = {
      "name"      = "netperf-operator"
      "namespace" = "${local.default-namespace}"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "name" = "netperf-operator"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "name" = "netperf-operator"
          }
        }
        "spec" = {
          "containers" = [
            {
              "command" = [
                "netperf-operator",
              ]
              "env" = [
                {
                  "name" = "WATCH_NAMESPACE"
                  "valueFrom" = {
                    "fieldRef" = {
                      "fieldPath" = "metadata.namespace"
                    }
                  }
                },
              ]
              "image"           = "tailoredcloud/netperf-operator:v0.1.1-742a3e1"
              "imagePullPolicy" = "Always"
              "name"            = "netperf-operator"
            },
          ]
        }
      }
    }
  }
}
