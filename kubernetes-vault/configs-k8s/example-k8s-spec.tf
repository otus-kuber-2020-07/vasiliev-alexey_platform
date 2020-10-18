
# увы не полетит баг 
# https://github.com/kubernetes-sigs/structured-merge-diff/issues/130
# починять в 1.20
terraform {
  required_version = ">= 0.12.26"
}

provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
}


resource "kubernetes_manifest" "pod_vault_agent_example" {

  provider = kubernetes-alpha

  depends_on = [
    kubernetes_manifest.configmap_example_vault_agent_config
  ]

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Pod"
    "metadata" = {
      "labels" = {
        "app" = "nginx-example"
      }
      "name"      = "vault-agent-example"
      "namespace" = "default"
    }
    "spec" = {
      "containers" = [
        {
          "image" = "nginx"
          "name"  = "nginx-container"
          "ports" = [
            {
              "containerPort" = 80
            },
          ]
          "volumeMounts" = [
            {
              "mountPath" = "/usr/share/nginx/html"
              "name"      = "shared-data"
            },
          ]
        },
      ]
      "initContainers" = [
        {
          "args" = [
            "agent",
            "-config=/etc/vault/vault-agent-config.hcl",
            "-log-level=debug",
          ]
          "env" = [
            {
              "name"  = "VAULT_ADDR"
              "value" = "http://vault:8200"
            },
          ]
          "image" = "vault"
          "name"  = "vault-agent"
          "volumeMounts" = [
            {
              "mountPath" = "/etc/vault"
              "name"      = "config"
            },
            {
              "mountPath" = "/etc/secrets"
              "name"      = "shared-data"
            },
          ]
        },
      ]
      "serviceAccountName" = "vault-auth"
      "volumes" = [
        {
          "configMap" = {
            "items" = [
              {
                "key"  = "vault-agent-config.hcl"
                "path" = "vault-agent-config.hcl"
              },
            ]
            "name" = "example-vault-agent-config"
          }
          "name" = "config"
        },
        {
          "emptyDir" = {}
          "name"     = "shared-data"
        },
      ]
    }
  }
}


resource "kubernetes_manifest" "configmap_example_vault_agent_config" {

  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "vault-agent-config.hcl" = "# Comment this out if running as sidecar instead of initContainer\nexit_after_auth = true\n\npid_file = \"/home/vault/pidfile\"\n\nauto_auth {\n    method \"kubernetes\" {\n        mount_path = \"auth/kubernetes\"\n        config = {\n            role = \"otus\"\n        }\n    }\n\n    sink \"file\" {\n        config = {\n            path = \"/home/vault/.vault-token\"\n        }\n    }\n}\n\ntemplate {\ndestination = \"/etc/secrets/index.html\"\ncontents = <<EOT\n<html>\n<body>\n<p>Some secrets:</p>\n{{- with secret \"otus/otus-ro/config\" }}\n<ul>\n<li><pre>username: {{ .Data.username }}</pre></li>\n<li><pre>password: {{ .Data.password }}</pre></li>\n</ul>\n{{ end }}\n</body>\n</html>\nEOT\n}\n"
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name"      = "example-vault-agent-config"
      "namespace" = "default"
    }
  }
}
