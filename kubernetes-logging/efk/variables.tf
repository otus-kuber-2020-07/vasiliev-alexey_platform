variable "is_minikube" {
  type    = bool
  default = false
}


variable "external_ip" {
  type    = string
  default = "35.241.153.3"
}


variable "efk_namespace" {
  type    = string
  default = "observability"
}


variable "project_name" {
  type = string
}

variable "region_name" {
  default = "europe-west1"
}