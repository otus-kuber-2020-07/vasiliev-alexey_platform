variable "project_name" {
  type    = string
}

variable "source_image_family" {
  type    = string
  default = "ubuntu-1804-lts"
}

variable "machine_type" {
  type    = string
    default = "e2-standard-2"
}
