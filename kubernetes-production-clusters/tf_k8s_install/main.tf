terraform {
  required_version = ">= 0.12.26"
}

provider "external" {
  version = "~> 1.2"
}

provider "google" {

  version = "~> 3.33.0"

  project = var.project_name
  region  = var.region
  zone    = var.zone

}
resource "google_compute_instance" "k8s-master" {
  name         = "k8s-master-0"
  tags         = ["k8s"]
   machine_type = var.master_machine_type
  boot_disk {
    initialize_params {
      image = "k8s-node-base"
    }
  }

  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }


  network_interface {
    network = "default"
    access_config {}
  }


  connection {
    type  = "ssh"
    host  = self.network_interface[0].access_config[0].nat_ip
    user  = "appuser"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }


  # Создание кластера
  provisioner "remote-exec" {
    inline = ["sudo kubeadm init  --pod-network-cidr=192.168.0.0/24"]
  }
  # Копируем конфиг kubectl
  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm init  --pod-network-cidr=192.168.0.0/24",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config"

    ]
  }

  # Проверим ноды
  provisioner "remote-exec" {
    inline = ["sudo kubectl get nodes"]
  }

  # Устанавливаем сетевой плагин
  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"]
  }
}


data "external" "k8s_join_response" {
  depends_on = [google_compute_instance.k8s-master]
  program    = ["sh", "get_token.sh"]
  query = {

    private_key = file(var.public_key_path),
    host        = "${google_compute_instance.k8s-master.network_interface[0].access_config[0].nat_ip}"
  }
}



resource "google_compute_instance" "k8s-worker" {
  name         = "k8s-worker-${count.index}"
  count = 3
  tags         = ["k8s"]
  machine_type = var.worker_machine_type
  boot_disk {
    initialize_params {
      image = "k8s-node-base"
    }
  }
  depends_on = [data.external.k8s_join_response]

  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }


  network_interface {
    network = "default"
    access_config {}
  }


  connection {
    type  = "ssh"
    host  = self.network_interface[0].access_config[0].nat_ip
    user  = "appuser"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }

  # Подключаем ноды
  provisioner "remote-exec" {
    inline = ["sudo ${data.external.k8s_join_response.result["command"]}"]
  }

}


