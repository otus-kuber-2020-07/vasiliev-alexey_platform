terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.00"

}


resource "helm_release" "fluxcd" {

  name             = "flux"
  chart            = "flux"
  namespace        = "flux"
  repository       = "https://charts.fluxcd.io"
  create_namespace = true

  values = [<<EOF
git:
  url: git@gitlab.com:vasiliev-alexey/microservices-demo.git
  path: deploy
  ciSkip: true	
  pollInterval: 1m
registry:
  automationInterval: 1m

EOF
  ]

}

resource "helm_release" "helm_operator" {

  name             = "helm-operator"
  chart            = "helm-operator"
  namespace        = "flux"
  repository       = "https://charts.fluxcd.io"
  create_namespace = true

 depends_on = [
    helm_release.fluxcd
  ]

  values = [<<EOF
helm:
  versions: v3
git:
  pollInterval: 1m
  ssh:
    secretName: flux-git-deploy

chartsSyncInterval: 1m

logReleaseDiffs:
  true

configureRepositories:
  enable: true
  repositories:
    - name: stable
      url: https://kubernetes-charts.storage.googleapis.com

EOF
  ]

  set {
    name  = "skip-crds"
    value = "true"
  }

  set {
    name  = "helm.versions"
    value = "v3"
  }

}




