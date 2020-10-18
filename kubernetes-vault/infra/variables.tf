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

variable "count_vms" {
  default = "3"
}
variable "dns_zone_name" {
  default = "example-com"
}


variable "machine_type" {
  default = "e2-standard-2"
}
