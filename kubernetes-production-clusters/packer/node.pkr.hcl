locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "googlecompute" "k8s-node-builder" {
  disk_size           = "10"
  disk_type           = "pd-ssd"
  image_description   = "Образ для k8s-node"
  image_family        = "k8s-node-base"
  image_name          = "k8s-node-base"
  machine_type        = "${var.machine_type}"
  network             = "default"
  project_id          = "${var.project_name}"
  source_image_family = "${var.source_image_family}"
  ssh_username        = "appuser"
  zone                = "europe-west1-b"
}

build {
  sources = ["source.googlecompute.k8s-node-builder"]

# Включаем маршрутизацию
provisioner "shell" {
  execute_command = "sudo -E -S sh '{{ .Path }}'"
  script       = "provision_k8s.sh"
  }


}
