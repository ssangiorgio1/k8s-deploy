
K8s: casi como en produccion

##  Objetivo
Implementar un flujo completo de despliegue en Kubernetes utilizando:
- Docker para construir una imagen personalizada.
- Docker Hub para alojar la imagen.
- Kubernetes con Minikube para desplegar el sitio web estático.

## 📚 Estructura del proyecto

```
├── sitio-k8s
│   ├── index.html
│   ├── style.css
│   └── Dockerfile
├── k8s-deploy
│   ├── deployment.yaml
│   └── service.yaml
```

## 📁 Descripción de carpetas
- `sitio-k8s/`: Contiene el sitio web  a desplegar con su hoja de estilo y el Dockerfile.
- `k8s-deploy/`: Contiene los manifiestos de Kubernetes para el deployment y el servicio.

## 🚀 Imagen Docker
Imagen personalizada subida a Docker Hub:

[joaquinsangiorgio/static-website](https://hub.docker.com/r/joaquinsangiorgio/static-website)

Para utilizarla:
```bash
docker pull joaquinsangiorgio/static-website
```

## 🚿 Comandos principales utilizados
```bash
# Iniciar Minikube con Docker como driver
minikube start -p produccion --driver=docker

# Crear la imagen y subirla a Docker Hub
docker build -t joaquinsangiorgio/static-website .
docker push joaquinsangiorgio/static-website

# Aplicar manifiestos de Kubernetes
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Exponer el sitio en el navegador
minikube service ejemplo-service -p produccion
```

## 👍 Resultado final
El sitio web se encuentra corriendo localmente en el entorno de Kubernetes, accediendo desde la URL que expone el servicio creado.

---

hecho por Mi, Joaquin Sangiorgio
