# 1. Instalar cert-manager (prerrequisito para Rancher)
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  # version    = "v1.13.3"
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }
}

# 2. Instalar Rancher
resource "helm_release" "rancher" {
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/latest"
  chart      = "rancher"
  # version    = "2.8.0"
  namespace  = "cattle-system"
  create_namespace = true

  depends_on = [helm_release.cert_manager]

  values = [
    yamlencode({
      # Configuración básica
      hostname = var.rancher_hostname
      bootstrapPassword = var.rancher_bootstrap_password
      
      # Configuración de ingress y TLS
      ingress = {
        tls = {
          source = "letsEncrypt"
        }
      }
      
      # Let's Encrypt
      letsEncrypt = {
        email = var.letsencrypt_email
        environment = "production"  # Cambiar a "staging" para pruebas
      }
      
      # Configuración de réplicas para alta disponibilidad
      replicas = 3
      
      # Recursos
      resources = {
        requests = {
          cpu    = "500m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
      }
      
      # Configuración adicional
      systemDefaultRegistry = ""
      useBundledSystemChart = false
      
      # Configuración de antiAffinity para distribuir pods
      antiAffinity = "preferred"
    })
  ]

  # Timeout aumentado para la instalación
  timeout = 600
  
  # Esperar a que la instalación esté completa
  wait = true
  wait_for_jobs = true
}

# Outputs
output "rancher_url" {
  description = "URL para acceder a Rancher"
  value       = "https://${var.rancher_hostname}"
}

output "rancher_bootstrap_password" {
  description = "Contraseña inicial de Rancher"
  value       = var.rancher_bootstrap_password
  sensitive   = true
}

output "installation_notes" {
  description = "Notas de instalación"
  value = <<EOF
Rancher ha sido instalado exitosamente!

1. Accede a Rancher en: https://${var.rancher_hostname}
2. Usuario: admin
3. Contraseña: ${var.rancher_bootstrap_password}

Verifica que tu DNS apunte a tu ingress controller.
EOF
  sensitive = true
}