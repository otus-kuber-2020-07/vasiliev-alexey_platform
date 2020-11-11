variable project_name {
  description = "Project ID"
}
variable region {
  description = "Region"
  default     = "europe-west1"
}
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "europe-west1-b"
}

variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
  default     = "~/.ssh/appuser.pub"
}

variable private_key_path {
  # Описание переменной
  description = "Path to the private key used for ssh access"
  default     = "~/.ssh/appuser"
}

variable node_machine_type {
  description = "Node machine type"
  default     = "n1-standard-1"
}


