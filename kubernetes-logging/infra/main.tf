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

resource "google_container_cluster" "av-k8s-cluster" {
  name     = var.cluster_name
  location = var.location_name

  # важно  отключить  Stackdriver,
  logging_service    = "none"
  monitoring_service = "none"

  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.location_name} --project ${var.project_name}"
  }

}

resource "google_container_node_pool" "av-k8s-nodes-app" {
  name       = "default-pool"
  location   = var.location_name
  cluster    = google_container_cluster.av-k8s-cluster.name
  node_count = var.app_count_vms

  node_config {
    preemptible  = true
    machine_type = var.app_machine_type
    disk_size_gb = 30

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}


resource "google_container_node_pool" "av-k8s-nodes-infra" {
  name       = "infra-pool"
  location   = var.location_name
  cluster    = google_container_cluster.av-k8s-cluster.name
  node_count = var.infra_count_vms

  node_config {
    preemptible  = true
    machine_type = var.infra_machine_type
    disk_size_gb = 30

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Присвоим  этим  нодам  определенный ,  чтобы  избежатьзапуска на них случайных pod
    taint {
      key    = "node-role"
      value  = "infra"
      effect = "NO_SCHEDULE"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_compute_address" "ip_address" {
  name = "ip-adress-for-nginx-ingress"

  depends_on = [
    google_container_node_pool.av-k8s-nodes-infra
  ]
}
