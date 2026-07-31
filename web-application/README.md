# Multi-service web-application

This update adds a frontend, backend, and postgres service to the web-application example.

## Services

- **frontend**: static HTML served by nginx, exposes port 80
- **backend**: Flask API that exposes /api/items on port 5000 and connects to Postgres
- **postgres**: Postgres 15 (single-replica) with an in-cluster volume (emptyDir by default)

## Docker Images

- **Frontend Image**: `venky913381/frontend-istio:latest`
- **Backend Image**: `venky913381/backend-istio:latest`

## Quickstart

### Step 1: Build and Push Docker Images

Build and push both frontend and backend images to Docker Hub:

```bash
# Build and push backend image
docker build -t venky913381/backend-istio:latest web-application/application/backend
docker push venky913381/backend-istio:latest

# Build and push frontend image
docker build -t venky913381/frontend-istio:latest web-application/application/frontend
docker push venky913381/frontend-istio:latest
```

**Note**: Ensure you're logged in to Docker Hub:
```bash
docker login
```

### Step 2: Manifests are Already Updated

The deployment manifests already include the correct image names:
- `web-application/manifests/backend-deployment.yaml` → `image: venky913381/backend-istio:latest`
- `web-application/manifests/frontend-deployment.yaml` → `image: venky913381/frontend-istio:latest`

**No manual image updates needed!**

### Step 3: Create Namespace and Deploy Services

First, create the namespace:

```bash
kubectl apply -f web-application/manifests/namespace.yaml
```

Then deploy PostgreSQL, backend, and frontend services:

```bash
kubectl apply -f web-application/manifests/postgres-deployment.yaml
kubectl apply -f web-application/manifests/backend-deployment.yaml
kubectl apply -f web-application/manifests/frontend-deployment.yaml
```

Verify deployments:
```bash
kubectl get pods -n web-app
kubectl get svc -n web-app
```

### Step 4: Initialize Database

Run a one-time database initialization job:

```bash
kubectl -n web-app run db-init \
  --rm -it \
  --image=venky913381/backend-istio:latest \
  --restart=Never \
  --env="DB_HOST=postgres" \
  --env="DB_USER=webapp" \
  --env="DB_PASSWORD=webapppass" \
  --env="DB_NAME=webappdb" \
  -- python -c "from backend import db; db.create_all()"
```

### Step 5: Apply Istio Routing

Deploy the Istio Gateway and VirtualService for traffic routing:

```bash
kubectl apply -f web-application/manifests/gateway.yaml
kubectl apply -f web-application/manifests/virtualservice.yaml
```

### Step 6: Test the Application

Get the Istio Ingress Gateway NodePort:

```bash
kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
```

Get a worker node IP:

```bash
kubectl get nodes -o wide
```

Test the endpoints:

```bash
# Frontend (serves HTML on port 80)
curl -v http://<NODE_IP>:<NODE_PORT>/

# Backend API
curl -v http://<NODE_IP>:<NODE_PORT>/api/items
```

## Architecture

```
Client
  │
  ▼
Istio Ingress Gateway (NodePort)
  │
  ▼
Istio Gateway
  │
  ▼
VirtualService
  │
  ├─→ Frontend Service (Port 80)
  │    └─→ frontend-xxxxx Pod
  │
  └─→ Backend Service (Port 5000)
       └─→ backend-xxxxx Pod
            │
            ▼
       PostgreSQL Service
```

## Troubleshooting

### ImagePullBackOff Error

If pods show `ImagePullBackOff`, verify images are pushed:

```bash
docker pull venky913381/backend-istio:latest
docker pull venky913381/frontend-istio:latest
```

Check pod logs:
```bash
kubectl describe pod -n web-app <pod-name>
kubectl logs -n web-app <pod-name>
```

### Database Connection Issues

Verify PostgreSQL pod is running:
```bash
kubectl get pods -n web-app
kubectl logs -n web-app postgres-xxxxx
```

Test connectivity from backend pod:
```bash
kubectl exec -it -n web-app backend-xxxxx -- sh
# Inside pod:
psql -h postgres -U webapp -d webappdb -c "SELECT 1"
```

### Port Access Issues

Port-forward to test locally:
```bash
kubectl port-forward -n web-app svc/frontend 8080:80
kubectl port-forward -n web-app svc/backend 5000:5000

# In another terminal:
curl http://localhost:8080/
curl http://localhost:5000/api/items
```

## Production Considerations

### Database Storage

For production, replace `emptyDir` with persistent storage:

```yaml
volumeClaimTemplates:
- metadata:
    name: postgres-storage
  spec:
    accessModes: [ "ReadWriteOnce" ]
    resources:
      requests:
        storage: 10Gi
```

### Secrets Management

Store database credentials in Kubernetes Secrets instead of environment variables:

```bash
kubectl create secret generic db-credentials \
  --from-literal=username=webapp \
  --from-literal=password=webapppass \
  -n web-app
```

Update deployments to reference the secret.

### Resource Limits

Add resource requests and limits:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Health Checks

Add liveness and readiness probes:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Notes

- Postgres uses `emptyDir` for quick testing; for production use PersistentVolumeClaim or StatefulSet
- Database credentials are in plaintext for this lab; use Kubernetes Secrets in production
- Images are publicly available on Docker Hub for easy pulling
- Ensure your Kubernetes cluster has Istio installed before deploying
