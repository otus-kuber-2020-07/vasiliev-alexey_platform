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

locals {
  worker_num = var.worker_num_2_upg
}


data "google_compute_instance" "k8s-master-0" {
  name = "k8s-master-0"
}

data "google_compute_instance" "k8s-worker" {
 name = "k8s-worker-${local.worker_num}"

}


resource "null_resource" "k8s-master-0-upg" {
  # ugly hack 
  triggers = { always_run = "${timestamp()}" }


  connection {
    type  = "ssh"
    host  = data.google_compute_instance.k8s-master-0.network_interface[0].access_config[0].nat_ip
    user  = "appuser"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }



  provisioner "remote-exec" {

    inline = [
      "sudo apt-get update && sudo apt-get install -y kubeadm=1.18.0-00 kubelet=1.18.0-00 kubectl=1.18.0-00",
      "sudo kubeadm upgrade plan",
      "sudo kubeadm upgrade apply -y v1.18.0",
      "echo ***************** version info ************************",
      "sudo kubeadm version && sudo kubelet --version && sudo kubectl version",
      "echo *******************************************"
    ]
  }


 provisioner "remote-exec" {

    inline = [
            "echo ***************** Вывод worker-нод из планирования ************************",
            "sudo kubectl drain k8s-worker-${local.worker_num} --ignore-daemonsets",

            "echo **************************************************************************",
      
    ]
  }

}


resource "null_resource" "k8s-worker-0-upg" {
   # ugly hack 
  triggers = { always_run = "${timestamp()}" }

depends_on= [null_resource.k8s-master-0-upg]


  connection {
    type  = "ssh"
    host  = data.google_compute_instance.k8s-worker.network_interface[0].access_config[0].nat_ip
    user  = "appuser"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }
  provisioner "remote-exec" {

    inline = [
       "echo ***************** upgrade worker-${local.worker_num} ************************",
      "sudo apt-get update && sudo apt-get install -y kubeadm=1.18.0-00 kubelet=1.18.0-00",
      "sudo systemctl restart kubelet",
      "echo ***************** version info ************************",
      "sudo kubeadm version && sudo kubelet --version",
      "echo *******************************************"
    ]
  }
}

resource "null_resource" "k8s-master-0-fin" {

  # ugly hack 
  triggers = { always_run = "${timestamp()}" }

depends_on= [null_resource.k8s-worker-0-upg, null_resource.k8s-master-0-upg]


  connection {
    type  = "ssh"
    host  = data.google_compute_instance.k8s-master-0.network_interface[0].access_config[0].nat_ip
    user  = "appuser"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }


provisioner "remote-exec" {

    inline = [
            "echo ***************** Возвращение ноды в планирование ************************",
            "sudo kubectl uncordon  k8s-worker-${local.worker_num}",
            "sudo kubectl get nodes",
            "echo **************************************************************************",
      
    ]
  }
}