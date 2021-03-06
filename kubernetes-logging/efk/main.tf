terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.00"

}

provider "google" {
  version = "~> 3.15.0"
  project = var.project_name
  region  = var.region_name
}


data "google_compute_address" "ip_address" {
  name = "ip-adress-for-nginx-ingress"
}


resource "helm_release" "nginx" {
  name             = "nginx"
  chart            = "stable/nginx-ingress"
  namespace        = "nginx-ingress"
  create_namespace = true

  # Должно быть развернуто три реплики controller
  values = [<<EOF
controller:
  replicaCount: 3

  config:
    log-format-escape-json: "true"
    log-format-upstream: '{"remote_addr": "$remote_addr", 
        "x-forward-for": "$proxy_add_x_forwarded_for", 
        "request_id": "$req_id", 
        "remote_user": "$remote_user", 
        "bytes_sent": "$bytes_sent", 
        "request_time": "$request_time", 
        "status": "$status",
        "vhost": "$host", 
        "request_proto": "$server_protocol", 
        "path": "$uri",
        "request_query": "$args", 
        "request_length": "$request_length",
        "duration": "$request_time", 
        "method": "$request_method", 
        "http_referrer": "$http_referer", 
        "http_user_agent": "$http_user_agent"}'

  tolerations:
    - key: node-role
      operator: Equal
      value: infra
      effect: NoSchedule

  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - nginx-ingress
          topologyKey: kubernetes.io/hostname

  nodeSelector: 
    cloud.google.com/gke-nodepool: infra-pool

  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: observability

EOF
  ]

  set {
    name  = "controller.service.loadBalancerIP"
    value = data.google_compute_address.ip_address.address
  }


}



resource "helm_release" "elasticsearch" {
  name             = "elasticsearch"
  chart            = "elasticsearch"
  namespace        = var.efk_namespace
  repository       = "https://helm.elastic.co"
  create_namespace = true

  values = [<<EOF
nodeSelector:
  cloud.google.com/gke-nodepool: infra-pool
tolerations:
- key: node-role
  operator: Equal
  value: infra
  effect: NoSchedule

EOF
  ]


}


resource "helm_release" "kibana" {
  name             = "kibana"
  chart            = "kibana"
  namespace        = var.efk_namespace
  repository       = "https://helm.elastic.co"
  create_namespace = true


  values = [<<EOF
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  path: /
  hosts:
  - kibana.${data.google_compute_address.ip_address.address}.xip.io

EOF
  ]

}

resource "helm_release" "fluent-bit" {
  name             = "fluent-bit"
  chart            = "stable/fluent-bit"
  namespace        = var.efk_namespace
  create_namespace = true

  values = [<<EOF
backend:
  type: es
  es:
    host: elasticsearch-master
rawConfig: |
  @INCLUDE fluent-bit-service.conf
  @INCLUDE fluent-bit-input.conf
  @INCLUDE fluent-bit-filter.conf
  @INCLUDE fluent-bit-output.conf

  [FILTER]
      Name modify
      Match *
      Remove time
      Remove @timestamp
tolerations:
- key: node-role
  operator: Equal
  value: infra
  effect: NoSchedule
EOF
  ]

}


resource "helm_release" "elasticsearch-exporter" {
  name             = "elasticsearch-exporter"
  chart            = "stable/elasticsearch-exporter"
  namespace        = var.efk_namespace
  create_namespace = true

  depends_on = [
    helm_release.elasticsearch
  ]

  values = [<<EOF
nodeSelector:
  cloud.google.com/gke-nodepool: infra-pool
tolerations:
- key: node-role
  operator: Equal
  value: infra
  effect: NoSchedule

EOF
  ]


  set {
    name  = "es.uri"
    value = "http://elasticsearch-master:9200"
  }

  set {
    name  = "serviceMonitor.enabled"
    value = "true"
  }

}



resource "helm_release" "prometheus-operator" {
  name             = "prometheus-operator"
  chart            = "stable/prometheus-operator"
  namespace        = var.efk_namespace
  create_namespace = true

  values = [<<EOF
prometheus:
  ingress:
      enabled: true
      annotations: {
        kubernetes.io/ingress.class: nginx
      }
      path: /
      hosts:
        - prometheus.${data.google_compute_address.ip_address.address}.xip.io
  prometheusSpec:
    tolerations:
    - key: node-role
      operator: Equal
      value: infra
      effect: NoSchedule
    serviceMonitorSelectorNilUsesHelmValues: false
grafana:
  ingress:
      enabled: true
      annotations: {
        kubernetes.io/ingress.class: nginx
      }
      path: /
      hosts:
        - grafana.${data.google_compute_address.ip_address.address}.xip.io
  additionalDataSources:
    - name: Loki
      type: loki
      url: http://loki.${var.efk_namespace}:3100/
      access: proxy


EOF
  ]


}



resource "helm_release" "loki" {
  name             = "loki"
  chart            = "loki"
  repository       = "https://grafana.github.io/loki/charts"
  namespace        = var.efk_namespace
  create_namespace = true
  depends_on       = [helm_release.prometheus-operator]
}


resource "helm_release" "promtail" {
  name             = "promtail"
  chart            = "promtail"
  repository       = "https://grafana.github.io/loki/charts"
  namespace        = var.efk_namespace
  create_namespace = true
  depends_on       = [helm_release.prometheus-operator]

  values = [<<EOF
tolerations:
  - key: node-role
    operator: Equal
    value: infra
    effect: NoSchedule
EOF
  ]
  set {
    name  = "loki.serviceName"
    value = "loki"
  }

}