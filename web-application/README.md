# web-application lab

This folder contains a minimal example application and Kubernetes + Istio manifests to deploy it into the cluster.

Structure

web-application/
  application/       # simple Flask app + Dockerfile
  manifests/         # k8s namespace, deployment, service + Istio gateway/virtualservice

Quickstart

1) Build and push a container image and update the deployment manifest:

```bash
# example (replace with your registry and image name)
docker build -t yourrepo/web-app:latest web-application/application
docker push yourrepo/web-app:latest

# edit web-application/manifests/deployment.yaml and replace IMAGE_PLACEHOLDER with your image
```

2) Apply the manifests (on the add-web-application branch or locally):

```bash
kubectl apply -f web-application/manifests/namespace.yaml
kubectl apply -f web-application/manifests/deployment.yaml
kubectl apply -f web-application/manifests/service.yaml
kubectl apply -f web-application/manifests/gateway.yaml
kubectl apply -f web-application/manifests/virtualservice.yaml
kubectl apply -f web-application/manifests/destinationrule.yaml
```

3) Test via Istio ingressgateway NodePort (or configure an external NGINX proxy like in the repo's nginx-proxy lab):

```bash
# get the ingressgateway NodePort
kubectl -n istio-system get svc istio-ingressgateway -o yaml

# curl to NODE_IP:NODE_PORT or configure nginx to proxy to it
```
