# Application

Multi-service demo app (frontend, backend, inventory, db) used to exercise the EKS cluster and for
Istio practice. All application code lives in this folder so it stays separate from the Terraform
infrastructure in the repo root.

```text
application/
├── backend/                  FastAPI REST API (users, products, orders) — port 8000
├── frontend/                 Flask web UI — port 5000
├── inventory/                FastAPI stock-lookup service, called only by backend — port 8001
├── db/                       init.sql (schema/seed reference; the backend also creates tables itself)
├── k8s/                      Kubernetes manifests for deploying to the EKS cluster
│   ├── namespace.yaml            "app" namespace, labeled for Istio sidecar injection
│   ├── serviceaccounts.yaml      One ServiceAccount per service (identity for AuthorizationPolicy)
│   ├── postgres.yaml             Postgres StatefulSet + headless Service + Secret
│   ├── backend.yaml              Backend Deployment + Service
│   ├── frontend.yaml             Frontend Deployment + Service
│   ├── inventory.yaml            Inventory Deployment + Service
│   ├── istio-gateway.yaml        Istio Gateway/VirtualServices exposing the frontend
│   ├── peer-authentication.yaml  Namespace-wide strict mTLS
│   └── authorization-policies.yaml  Allow/deny rules between services (see below)
└── docker-compose.yml        Local dev: run all four services together
```

## Service call graph

```text
client -> [Istio ingress gateway] -> frontend -> backend -> postgres
                                                     |
                                                     v
                                                inventory
```

`frontend` never calls `inventory` directly — only `backend` does (to check stock before
confirming an order). This gives the mesh a real edge to explicitly **deny**, alongside the edges
it explicitly **allows**.

## Local development

```bash
cd application
docker-compose up --build
```

- Frontend: http://localhost:5000
- Backend API docs: http://localhost:8000/docs
- Inventory API docs: http://localhost:8001/docs

## Deploying to EKS

1. Deploy the EKS cluster via the existing `deploy-eks.yml` workflow / `environments/<env>/eks` Terraform.
2. Build and push images via `.github/workflows/deploy-app.yml` (builds `application/backend`,
   `application/frontend`, and `application/inventory`, pushes to ECR).
3. Point `kubectl` at the cluster and apply the base manifests:

   ```bash
   kubectl apply -f application/k8s/namespace.yaml
   kubectl apply -f application/k8s/serviceaccounts.yaml
   kubectl apply -f application/k8s/postgres.yaml
   kubectl apply -f application/k8s/backend.yaml
   kubectl apply -f application/k8s/frontend.yaml
   kubectl apply -f application/k8s/inventory.yaml
   ```

   Replace the `<ECR_BACKEND_REPO>`/`<ECR_FRONTEND_REPO>`/`<ECR_INVENTORY_REPO>` image placeholders
   in `backend.yaml`, `frontend.yaml`, and `inventory.yaml` with the actual ECR image URIs before
   applying (or template them in CI).

4. Once Istio is installed on the cluster, apply the gateway and security policies:

   ```bash
   kubectl apply -f application/k8s/istio-gateway.yaml
   kubectl apply -f application/k8s/peer-authentication.yaml
   kubectl apply -f application/k8s/authorization-policies.yaml
   ```

   The `app` namespace already carries the `istio-injection: enabled` label, so pods created after
   Istio is installed get the sidecar automatically (recreate pods if Istio was installed after
   the app).

## Practicing service-to-service allow/deny

`authorization-policies.yaml` enforces:

| From | To | Result |
|---|---|---|
| Istio ingress gateway | frontend | allow |
| frontend | backend | allow |
| backend | inventory | allow |
| **frontend** | **inventory** | **deny** (explicit) |
| backend | postgres | allow |

Verify it once the policies are applied:

```bash
# From a frontend pod: denied (403 RBAC: access denied)
kubectl exec -n app deploy/frontend -c frontend -- curl -s -o /dev/null -w "%{http_code}\n" http://inventory:8001/api/health

# From a backend pod: allowed (200)
kubectl exec -n app deploy/backend -c backend -- curl -s -o /dev/null -w "%{http_code}\n" http://inventory:8001/api/health
```

`AuthorizationPolicy` principals are only meaningful once mTLS is enforced, which is why
`peer-authentication.yaml` (namespace-wide `STRICT` mode) ships alongside it.
