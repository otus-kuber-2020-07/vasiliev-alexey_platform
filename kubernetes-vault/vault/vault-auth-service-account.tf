resource "kubernetes_manifest" "service-account-vault" {
  provider = kubernetes-alpha

depends_on = [
   helm_release.vault
  ]

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "ServiceAccount"
    "metadata" = {
      "name"      = "vault-auth"
      "namespace" = "default"
    }
  }
}




resource "kubernetes_manifest" "clusterrolebinding_role_tokenreview_binding" {
  provider = kubernetes-alpha

 depends_on = [
    kubernetes_manifest.service-account-vault
  ]

  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1beta1"
    "kind"       = "ClusterRoleBinding"
    "metadata" = {
      "name"      = "role-tokenreview-binding"
      "namespace" = "default"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind"     = "ClusterRole"
      "name"     = "system:auth-delegator"
    }
    "subjects" = [
      {
        "kind"      = "ServiceAccount"
        "name"      = "vault-auth"
        "namespace" = "default"
      },
    ]
  }
}


