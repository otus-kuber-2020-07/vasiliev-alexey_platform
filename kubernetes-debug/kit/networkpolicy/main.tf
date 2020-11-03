
provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
}



terraform {
  required_version = ">= 0.12.26"
}

locals {
  namespace = "default"
}



# resource "kubernetes_manifest" "netperf_example" {
#   provider = kubernetes-alpha
#   manifest = {
#     "apiVersion" = "app.example.com/v1alpha1"
#     "kind"       = "Netperf"
#     "metadata" = {
#       "name"      = "example"
#       "namespace" = "${local.namespace}"
#     }
#   }
# }
# resource "kubernetes_manifest" "networkpolicy_netperf_calico_policy" {
#   provider = kubernetes-alpha
#   manifest = {
#     "apiVersion" = "crd.projectcalico.org/v1"
#     "kind"       = "NetworkPolicy"

#     "metadata" = {
#       "labels" = null
#       "name"   = "netperf-calico-policy"
#           "namespace"  = "${local.namespace}"
#     }
#     "spec" = {
#       "egress" = [
#         {
#           "action" = "Allow"
#           "destination" = {
#             "selector" = "netperf-role == \"netperf-operator\""
#           }
#         },
#         {
#           "action" = "Log"
#         },
#         {
#           "action" = "Deny"
#         },
#       ]
#       "ingress" = [
#         {
#           "action" = "Allow"
#           "source" = {
#             "selector" = "netperf-role == \"netperf-operator\""
#           }
#         },
#         {
#           "action" = "Log"
#         },
#         {
#           "action" = "Deny"
#         },
#       ]
#       "order"    = 10
#       "selector" = "app == \"netperf-operator\""
#     }
#   }
# }
resource "kubernetes_manifest" "networkpolicy_netperf_calico_policy" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "crd.projectcalico.org/v1"
    "kind" = "NetworkPolicy"
    "metadata" = {
      "labels" = null
      "name" = "netperf-calico-policy"
       "namespace"  = "${local.namespace}"
    }
    "spec" = {
      "egress" = [
        {
          "action" = "Allow"
          "destination" = {
            "selector" = "app == \"netperf-operator\""
          }
        },
        {
          "action" = "Log"
        },
        {
          "action" = "Deny"
        },
      ]
      "ingress" = [
        {
          "action" = "Allow"
          "source" = {
            "selector" = "app == \"netperf-operator\""
          }
        },
        {
          "action" = "Log"
        },
        {
          "action" = "Deny"
        },
      ]
      "order" = 10
      "selector" = "app == \"netperf-operator\""
    }
  }
}
