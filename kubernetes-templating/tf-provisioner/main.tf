terraform {
  required_version = ">= 0.12.26"
}


provider "helm" {
  version = "~> 1.00"

}


resource "helm_release" "nginx" {
  name             = "nginx"
  chart            = "stable/nginx-ingress"
  namespace        = "nginx-ingress"
  create_namespace = true

  set {
    name  = "controller.service.loadBalancerIP"
    value = "${var.loadBalancerIP}"
  }

}


resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  chart            = "jetstack/cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "0.16.1"
  # installCRDs 
  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    helm_release.nginx
  ]



  # https://github.com/jetstack/cert-manager/issues/2602#issuecomment-669091541 
  provisioner "local-exec" {
    command = "kubectl delete mutatingwebhookconfiguration.admissionregistration.k8s.io cert-manager-webhook"
  }
  provisioner "local-exec" {
    command = "kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io cert-manager-webhook"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ../cert-manager/clusterissuer.yaml"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete -f ../cert-manager/clusterissuer.yaml  --ignore-not-found "
  }




}



resource "helm_release" "chartmuseum" {
  name             = "chartmuseum"
  chart            = "stable/chartmuseum"
  namespace        = "chartmuseum"
  create_namespace = true
  depends_on = [
    helm_release.cert-manager,
    helm_release.nginx
  ]
  version = "2.13.2"
  values = [
    "${file("../chartmuseum/values.yaml")}"
  ]
  set {
    name  = "ingress.hosts[0].name"
    value = "chartmuseum.${var.loadBalancerIP}.nip.io"
  }
}



resource "helm_release" "harbor" {
  name       = "harbor"
  chart      = "harbor"
  repository = "https://helm.goharbor.io"

  namespace        = "harbor"
  create_namespace = true
  timeout          = 600
  wait             = true
  depends_on = [
    helm_release.cert-manager,
    helm_release.nginx
  ]
  version = "1.1.2"
  values = [
    "${file("../harbor/values.yaml")}"
  ]
  set {
    name  = "expose.ingress.hosts.core"
    value = "harbor.${var.loadBalancerIP}.sslip.io"
  }
}


