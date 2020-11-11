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

variable worker_num_2_upg {
  # Описание переменной
  description = "index worker node to upgrade"
  default     = 2
}



