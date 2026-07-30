# Multi-service web-application

This update adds a frontend, backend, and postgres service to the web-application example.

Services
- frontend: static HTML served by nginx, exposes port 80
- backend: Flask API that exposes /api/items on port 5000 and connects to Postgres
- postgres: Postgres 15 (single-replica) with an in-cluster volume (emptyDir by default)

Images
- Replace IMAGE_BACKEND and IMAGE_FRONTEND in the manifest files with the images you build and push.

Quickstart
1) Build and push images:

```bash
# backend
docker build -t yourrepo/web-app-backend:latest web-application/application/backend
docker push yourrepo/web-app-backend:latest

# frontend
docker build -t yourrepo/web-app-frontend:latest web-application/application/frontend
docker push yourrepo/web-app-frontend:latest
```

2) Update manifests with image names (deployment files):
- web-application/manifests/backend-deployment.yaml -> set image: yourrepo/web-app-backend:latest
- web-application/manifests/frontend-deployment.yaml -> set image: yourrepo/web-app-frontend:latest

3) Apply manifests (namespace first):

```bash
kubectl apply -f web-application/manifests/namespace.yaml
kubectl apply -f web-application/manifests/postgres-deployment.yaml
kubectl apply -f web-application/manifests/backend-deployment.yaml
kubectl apply -f web-application/manifests/frontend-deployment.yaml
```

4) Initialize DB (run one-time job/pod):

```bash
kubectl -n web-app run db-init --rm -dit --image=yourrepo/web-app-backend:latest --restart=Never --env="DB_HOST=postgres" --env="DB_USER=webapp" --env="DB_PASSWORD=webapppass" --env="DB_NAME=webappdb" -- python init_db.py
```

5) Apply Istio routing (gateway already present):

```bash
kubectl apply -f web-application/manifests/gateway.yaml
kubectl apply -f web-application/manifests/virtualservice.yaml
```

6) Test via Istio ingressgateway NodePort or nginx proxy like in the repo:

- Frontend: http://<NODE_IP>:<NODE_PORT>/  (served by frontend)
- Backend API: http://<NODE_IP>:<NODE_PORT>/api/items

Notes
- Postgres uses emptyDir for quick testing; for production use a PersistentVolumeClaim or StatefulSet.
- Secrets (DB password) are in plaintext for this lab; replace with Kubernetes Secrets in real setups.
