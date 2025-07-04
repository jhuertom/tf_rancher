# Variables
variable "rancher_hostname" {
  description = "Hostname para acceder a Rancher"
  type        = string
  default     = "rancher.example.com"
}

variable "rancher_bootstrap_password" {
  description = "Contraseña inicial para el usuario admin de Rancher"
  type        = string
  sensitive   = true
}

variable "letsencrypt_email" {
  description = "Email para Let's Encrypt"
  type        = string
}

variable "kubeconfig_path" {
  description = "Ruta al archivo kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

