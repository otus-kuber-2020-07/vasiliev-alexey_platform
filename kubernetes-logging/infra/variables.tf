variable "project_name" {
  type = string
}

variable "cluster_name" {
  default = "av-k8s-cluster"
}

variable "region_name" {
  default = "europe-west1"
}

variable "location_name" {
  default = "europe-west1-b"
}

variable "infra_count_vms" {
  default = "3"
}

variable "app_count_vms" {
  default = "1"
}

variable "dns_zone_name" {
  default = "example-com"
}


variable "infra_machine_type" {
  default = "e2-standard-2"
}


variable "app_machine_type" {
  default = "e2-standard-2"
}