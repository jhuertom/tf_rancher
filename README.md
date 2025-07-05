## 01 - tf_talos
terraform workspace new rancher
terraform init
terraform apply

terraform workspace new talos
terraform init
terraform apply

cp kubeconfig-rancher.yaml ~/.kube/config

## 02 - tf_rancher
terraform init
terraform apply

#### ################################################################################################
# Añadir el repositorio de HAProxy
helm repo add haproxy-ingress https://haproxy-ingress.github.io/charts

# Actualizar repositorios
helm repo update

# Instalar HAProxy Ingress Controller
helm install haproxy-ingress haproxy-ingress/haproxy-ingress \
  --create-namespace \
  --namespace haproxy-controller \
  --set controller.hostNetwork=true \
  --set controller.kind=DaemonSet \
  --set controller.ingressClass=haproxy

#### ################################################################################################
http:80►32757 https:443►30417 quic:443►30417╱UDP stat:1024►30958 admin:6060►31964