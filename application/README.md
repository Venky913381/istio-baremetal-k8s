# Istio POC application

A small 3-service shop used to try out Istio traffic management, resilience, security and egress features on the EKS cluster built by [`terraform/`](../terraform).

```
Internet ──> AWS LB ──> istio-ingressgateway ──> frontend ──> backend v1 / v2 ──> inventory
                                                              (subsets)
Test clients:  istio-poc/curl (in mesh) · istio-poc/fortio (load) · legacy/curl (no sidecar)
```

| Service | What it does | Useful endpoints |
|---|---|---|
| `frontend` | Web page + JSON API; forwards routing/tracing headers | `/`, `/api/products`, `/api/flaky`, `/api/egress` (calls https://httpbin.org/get) |
| `backend` | Product list. **v1** = no ratings (blue), **v2** = ratings (red) | `/api/products`, `/api/flaky` (fails 50% with HTTP 500) |
| `inventory` | Stock levels | `/api/stock` |

All services are Python/Flask on port 8080, with a Dockerfile each in `services/<name>/`.

## Layout

```
application/
├── services/{frontend,backend,inventory}/   app.py, requirements.txt, Dockerfile
├── docker-compose.yml                       run locally without Kubernetes
├── k8s/                                     Namespaces, Deployments, Services, test clients (kustomize)
└── istio/
    ├── install/istio-config.yaml            istioctl install settings (small-node sizing)
    ├── base/                                Gateway, DestinationRules, default routing (all -> v1)
    └── scenarios/NN-name/                   one folder per scenario
```

## Deploy (GitHub Actions)

1. **Terraform - VPC & EKS** → `apply`. This creates the VPC, the EKS cluster and the ECR repositories.
2. **App - Build, Istio & Scenarios** → `deploy-all`. This builds and pushes the images, installs Istio 1.31, and deploys the app and base routing. The run summary prints the app URL.
3. **App - Build, Istio & Scenarios** → `apply-scenario` with a scenario from the list below. Each run first removes the previous scenario, so scenarios never stack. Choose `base` to reset.
4. When you're finished: run the app pipeline with `uninstall` (optional), then the Terraform pipeline with `destroy`. The destroy run deletes the Istio load balancer first.

Other actions: `build-push` (images only), `install-istio`, and `deploy-app` (uses `image_tag`, or `latest`).

## Test from your machine

Your IAM identity needs cluster access. It has access automatically if it's the same identity the pipeline uses; otherwise add it to `admin_principal_arns` in `terraform/terraform.tfvars`.

```bash
aws eks update-kubeconfig --region us-east-1 --name istio-k8s-dev
export GW=http://$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -s $GW/api/products | jq

# helper: count backend versions over 20 requests
versions() { for i in $(seq 20); do curl -s "$@" $GW/api/products | jq -r .backend.version; done | sort | uniq -c; }
# helper: count HTTP status codes over N requests to a path
codes() { for i in $(seq ${2:-20}); do curl -s -o /dev/null -w "%{http_code}\n" $GW$1; done | sort | uniq -c; }
```

## Scenarios

| # | Scenario | Test | Expected |
|---|---|---|---|
| – | `base` | `versions` | 20 × `v1` |
| 01 | Canary traffic split (80/20) | `versions` | ~16 `v1`, ~4 `v2` |
| 02 | Header-based routing | `versions -H "end-user: tester"` · browser: `$GW/?user=tester` | all `v2` with the header, all `v1` without |
| 03 | Fault injection – delay | `time curl -s $GW/api/products >/dev/null` | ~3 s, still HTTP 200 |
| 04 | Fault injection – abort | `for i in $(seq 10); do curl -s $GW/api/products \| jq -c .backend.inventory; done` | ~half show `"status":500,"error":...` |
| 05 | Timeout | `time curl -s -w "\n%{http_code}\n" $GW/api/products` | `504` / `upstream request timeout` after ~2 s, not 5 s |
| 06 | Retries | `codes /api/flaky 20`, before and after applying | before ~50% `500`; after almost all `200` |
| 07 | Circuit breaker | `kubectl -n istio-poc exec deploy/fortio -c fortio -- fortio load -c 4 -qps 0 -n 40 -loglevel Warning http://backend:8080/api/products` | several `Code 503` (upstream overflow) |
| 08 | Traffic mirroring | `versions`, then `kubectl -n istio-poc logs deploy/backend-v2 -c backend --tail=20` | responses all `v1`, but v2 logs show the same requests |
| 09 | mTLS STRICT | `kubectl -n legacy exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}\n" http://backend.istio-poc:8080/api/products` | `200` before; `000` / connection reset after. The in-mesh `istio-poc/curl` still gets `200`. |
| 10 | Authorization policies (zero trust) | `curl -s $GW/api/products` and `kubectl -n istio-poc exec deploy/curl -c curl -- curl -s http://backend:8080/api/products` | gateway path works; direct call → `RBAC: access denied` (403) |
| 11 | JWT authentication | `curl -s -o /dev/null -w "%{http_code}\n" $GW/api/products` · then with `-H "Authorization: Bearer $TOKEN"` | `403` without a token, `200` with a valid one, `401` with a bad one. The page `/` stays public. |
| 12 | Egress blocked (REGISTRY_ONLY) | `curl -s $GW/api/egress \| jq .status` | error (`503`): external host not in the mesh registry |
| 13 | Egress allowed (ServiceEntry) | `curl -s $GW/api/egress \| jq .status` | `200`; only `httpbin.org` is allow-listed |
| 14 | Local rate limit | `codes /api/products 15` | 10 × `200`, then `429` |

For 11, get the token with:

```bash
TOKEN=$(curl -s https://raw.githubusercontent.com/istio/istio/release-1.31/security/tools/jwt/samples/demo.jwt)
```

### Debugging

```bash
kubectl -n istio-poc get pods                              # each app pod should show 2/2 (app + istio-proxy)
kubectl -n istio-poc logs deploy/frontend -c istio-proxy   # Envoy access logs (response flags: UO, UF, DI, FI, ...)
istioctl analyze -n istio-poc                              # config validation
istioctl proxy-config routes deploy/frontend -n istio-poc  # what Envoy actually received
```

### Optional: observability

Prometheus and Kiali give a live service graph, but they need more memory than the 2 × t3.small POC nodes have. Switch `node_instance_types` to `["t3.medium", "t3a.medium"]` first, then run:

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.31/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.31/samples/addons/kiali.yaml
istioctl dashboard kiali
```

## Run locally

```bash
cd application
docker compose up --build    # http://localhost:8080
```
