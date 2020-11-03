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

resource "kubernetes_manifest" "daemonset_kube_iptables_tailer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "DaemonSet"
    "metadata" = {
      "name" = "kube-iptables-tailer"
      "namespace" = "kube-system"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "app" = "kube-iptables-tailer"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "kube-iptables-tailer"
          }
        }
        "spec" = {
          "containers" = [
            {
              "command" = [
                "/kube-iptables-tailer",
                "--log_dir=/my-service-logs",
                "--v=4",
              ]
              "env" = [
                {
                  "name" = "JOURNAL_DIRECTORY"
                  "value" = "/var/log/journal"
                },
                {
                  "name" = "POD_IDENTIFIER"
                  "value" = "name"
                },
                {
                  "name" = "IPTABLES_LOG_PREFIX"
                  "value" = "calico-packet:"
                },
              ]
              "image" = "virtualshuric/kube-iptables-tailer:8d4296a"
              "imagePullPolicy" = "Always"
              "name" = "kube-iptables-tailer"
              "volumeMounts" = [
                {
                  "mountPath" = "/var/log/"
                  "name" = "iptables-logs"
                  "readOnly" = true
                },
                {
                  "mountPath" = "/my-service-logs"
                  "name" = "service-logs"
                },
              ]
            },
          ]
          "serviceAccountName" = "kube-iptables-tailer"
          "volumes" = [
            {
              "hostPath" = {
                "path" = "/var/log"
              }
              "name" = "iptables-logs"
            },
            {
              "emptyDir" = {}
              "name" = "service-logs"
            },
          ]
        }
      }
    }
  }
}
resource "kubernetes_manifest" "clusterrole_kube_iptables_tailer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRole"
    "metadata" = {
      "name" = "kube-iptables-tailer"
       "namespace" = "${local.default-namespace}"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "pods",
        ]
        "verbs" = [
          "list",
          "get",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "events",
        ]
        "verbs" = [
          "patch",
          "create",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "serviceaccount_kube_iptables_tailer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "v1"
    "kind" = "ServiceAccount"
    "metadata" = {
      "name" = "kube-iptables-tailer"
      "namespace" = "kube-system"
    }
  }
}

resource "kubernetes_manifest" "clusterrolebinding_kube_iptables_tailer" {
  provider = kubernetes-alpha
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRoleBinding"
    "metadata" = {
      "name" = "kube-iptables-tailer"
       "namespace" = "${local.default-namespace}"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind" = "ClusterRole"
      "name" = "kube-iptables-tailer"
    }
    "subjects" = [
      {
        "kind" = "ServiceAccount"
        "name" = "kube-iptables-tailer"
        "namespace" = "kube-system"
      },
    ]
  }
}
