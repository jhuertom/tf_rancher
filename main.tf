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
        ingressClassName = "haproxy"
        tls = {
          source = "letsEncrypt"
        }
        extraAnnotations = {
          "haproxy.org/ssl-redirect"       = "true"
          "haproxy.org/load-balance"       = "roundrobin"
          "haproxy.org/check"              = "true"
          "haproxy.org/check-http"         = "/ping"
          "haproxy.org/request-set-header" = <<-EOT
            X-Forwarded-Proto https
            X-Forwarded-Port 443
          EOT
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

resource "kubernetes_namespace" "haproxy_controller" {
  metadata {
    name = "haproxy-controller"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "haproxy_ingress" {
  name       = "haproxy-ingress"
  repository = "https://haproxytech.github.io/helm-charts"
  chart      = "kubernetes-ingress"
  namespace  = kubernetes_namespace.haproxy_controller.metadata[0].name
  create_namespace = false
  depends_on = [helm_release.rancher, kubernetes_namespace.haproxy_controller]

  set {
    name  = "controller.service.nodePorts.http"
    value = 32757
  }

  set {
    name  = "controller.service.nodePorts.https"
    value = 30417
  }

  set {
    name  = "controller.service.nodePorts.stat"
    value = 30958
  }

  set {
    name  = "controller.service.nodePorts.prometheus"
    value = 30003
  }

  timeout = 300
  wait = true
}