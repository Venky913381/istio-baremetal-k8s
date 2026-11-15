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
├── k8s/                                     Namespaces, Deployments, Services, test clients (plain YAML, numbered)
└── istio/
    ├── install/istio-config.yaml            istioctl install settings (small-node sizing)
    ├── base/                                Gateway, DestinationRules, default routing (all -> v1)
    └── scenarios/NN-name/                   one folder per scenario
```

## Deploy

Only the infrastructure has a pipeline. Everything on the cluster is deployed by hand, step by step.

Tools you need locally: `aws` CLI, `docker`, `kubectl`, `istioctl` 1.31, `jq`. The commands are bash; on Windows run them in Git Bash.

### 1. Create the infrastructure (GitHub Actions)

Run **Terraform - VPC & EKS** with `apply`. This creates the VPC, the EKS cluster and the ECR repositories (`istio-k8s-<env>/frontend|backend|inventory`).

Your IAM identity needs cluster access. It has access automatically if it's the same identity the pipeline uses; otherwise add it to `admin_principal_arns` in `terraform/terraform.tfvars` and re-run `apply`.

### 2. Point kubectl at the cluster

```bash
cd application
export AWS_REGION=us-east-1 ENV=dev     # use the region/env your Terraform pipeline deployed to
export NAME_PREFIX=istio-k8s-$ENV
aws eks update-kubeconfig --region $AWS_REGION --name $NAME_PREFIX
kubectl get nodes                      # 2 nodes, Ready
```

### 3. Build and push the images to ECR

```bash
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REGISTRY=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
export TAG=v1   # the k8s manifests use v1; if you change it, change the image tags in k8s/ too

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY
for svc in frontend backend inventory; do
  docker build -t $REGISTRY/$NAME_PREFIX/$svc:$TAG services/$svc
  docker push $REGISTRY/$NAME_PREFIX/$svc:$TAG
done
```

### 4. Install Istio

Download `istioctl` 1.31.0 from https://github.com/istio/istio/releases/tag/1.31.0 (on Windows: `istio-1.31.0-win.zip`, then put `bin/` on your `PATH`).

```bash
istioctl version --remote=false
istioctl install -y -f istio/install/istio-config.yaml    # istiod + ingress gateway (creates an AWS LB)
kubectl -n istio-system get pods
```

### 5. Deploy the application

The manifests in `k8s/` are plain YAML, numbered in the order they must be applied (namespaces first). The image lines in `01-inventory.yaml`, `02-backend.yaml` and `03-frontend.yaml` contain placeholders:

```
image: <ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/istio-k8s-<ENV>/backend:v1
```

Replace them by hand, or with the variables from steps 2 and 3:

```bash
sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/; s/<AWS_REGION>/$AWS_REGION/; s/<ENV>/$ENV/" k8s/*.yaml   # don't commit the result
grep -n "image:" k8s/*.yaml                                                                 # check
```

```bash
kubectl apply -f k8s/00-namespaces.yaml    # istio-poc (sidecar injection on) and legacy
kubectl apply -f k8s/01-inventory.yaml
kubectl apply -f k8s/02-backend.yaml       # backend-v1 and backend-v2 behind one Service
kubectl apply -f k8s/03-frontend.yaml
kubectl apply -f k8s/04-clients.yaml       # curl, fortio, legacy/curl test clients
# (or all at once: kubectl apply -f k8s/)

kubectl apply -f istio/base/                    # Gateway, DestinationRules, default routing (all -> v1)
kubectl -n istio-poc get pods                   # app pods show 2/2 (app + istio-proxy)
```

### 6. Apply a scenario

Every scenario resource carries the label `poc-scenario`. Remove the previous scenario first so scenarios never stack, re-apply base, then apply the new one:

```bash
KINDS=virtualservices,destinationrules,serviceentries,sidecars,envoyfilters,peerauthentications,requestauthentications,authorizationpolicies

kubectl -n istio-poc delete $KINDS -l poc-scenario --ignore-not-found   # reset
kubectl apply -f istio/base/
kubectl apply -f istio/scenarios/01-canary-traffic-split/                 # pick one from the table below
kubectl -n istio-poc get $KINDS -L poc-scenario                           # what is active now
```

Run only the first two commands to go back to `base`.

### 7. Clean up

```bash
kubectl delete -f k8s/ --ignore-not-found
istioctl uninstall --purge -y
kubectl delete namespace istio-system --ignore-not-found
```

Then run **Terraform - VPC & EKS** with `destroy` (type `destroy` in `confirm_destroy`). It also deletes any leftover Kubernetes load balancer before removing the VPC.

## Test from your machine

```bash
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
