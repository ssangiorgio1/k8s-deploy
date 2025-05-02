#!/bin/bash

set -e  # Detener ante cualquier error

# --- SOLICITAR CREDENCIALES DE GITHUB ---
read -p "👤 Ingresá tu usuario de GitHub: " GITHUB_USER
read -sp "🔐 Ingresá tu token personal (PAT): " GITHUB_TOKEN
echo
REPO_NAME="k8s-proyecto"
DESCRIPTION="Despliegue automático con Minikube, Docker y GitHub"

# --- VERIFICAR QUE NO ESTÉS COMO root ---
if [ "$EUID" -eq 0 ]; then
  echo "⚠️ No ejecutes este script como root. Usá: bash deploy_total.sh"
  exit 1
fi

# --- DEPENDENCIAS ---
echo "🔧 Instalando dependencias del sistema..."
sudo apt update && sudo apt install -y \
    curl wget apt-transport-https ca-certificates gnupg \
    lsb-release software-properties-common git

# --- DOCKER ---
echo "🐳 Instalando Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sudo bash
  sudo usermod -aG docker "$USER"
  echo "🔁 Cerrá sesión y volvé a entrar para que Docker funcione sin sudo."
else
  echo "✅ Docker ya instalado."
fi

# --- KUBECTL ---
echo "📦 Instalando kubectl..."
sudo curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# --- MINIKUBE ---
echo "🚀 Instalando Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# --- INICIAR MINIKUBE ---
echo "🚀 Iniciando Minikube con Docker driver..."
sudo systemctl enable docker
sudo systemctl start docker
sleep 3
minikube start --driver=docker
eval $(minikube docker-env)

# --- CREAR PROYECTO ---
echo "📁 Creando estructura del proyecto..."
mkdir -p "$REPO_NAME/k8s"
cd "$REPO_NAME"

# index.html
cat <<EOF > index.html
<!DOCTYPE html>
<html>
<head><title>Hola desde Kubernetes</title></head>
<body><h1>¡Desplegado automáticamente con Minikube!</h1></body>
</html>
EOF

# Dockerfile
cat <<EOF > Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EOF

# YAML
cat <<EOF > k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: web-static
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30036
EOF

# --- BUILD DOCKER IMAGE ---
echo "🔨 Construyendo imagen Docker..."
docker build -t web-static .

# --- APLICAR DEPLOYMENT ---
echo "📦 Desplegando en Kubernetes..."
kubectl apply -f k8s/deployment.yaml

# --- CREAR REPO EN GITHUB ---
echo "📡 Creando repositorio en GitHub..."
curl -u "$GITHUB_USER:$GITHUB_TOKEN" https://api.github.com/user/repos -d "{
  \"name\": \"$REPO_NAME\",
  \"description\": \"$DESCRIPTION\",
  \"private\": false
}"

# --- GIT INIT & PUSH ---
echo "📤 Subiendo código al repositorio..."
git init
git config user.name "$GITHUB_USER"
git config user.email "$GITHUB_USER@users.noreply.github.com"
git add .
git commit -m "Commit inicial automático"
git branch -M main
git remote add origin https://"$GITHUB_USER":"$GITHUB_TOKEN"@github.com/"$GITHUB_USER"/"$REPO_NAME".git
git push -u origin main

# --- MOSTRAR RESULTADO ---
echo "✅ Todo completado exitosamente."
echo "🌐 Accedé a tu sitio con: minikube service web-service"
echo "🔗 Repositorio: https://github.com/$GITHUB_USER/$REPO_NAME"
