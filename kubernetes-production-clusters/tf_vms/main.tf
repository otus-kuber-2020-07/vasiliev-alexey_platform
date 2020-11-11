terraform {
  required_version = ">= 0.12.26"
}

provider "google" {

  version = "~> 3.33.0"

  project = var.project_name
  region  = var.region
  zone    = var.zone

}
resource "google_compute_instance" "k8s-node" {
  name         = "k8s-node-${count.index}"
  tags         = ["k8s"]
  count        = 4
  machine_type = var.node_machine_type
  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }


  network_interface {
    network = "default"
    access_config {}
  }

}

