# Istio Bare Metal - NGINX Reverse Proxy

This guide demonstrates how to expose applications running inside a bare-metal Kubernetes cluster using **NGINX** as the external reverse proxy instead of a cloud LoadBalancer or MetalLB.

## Architecture

```text
                Client
                   │
                   ▼
        NGINX Reverse Proxy
                   │
                   ▼
      Node IP + NodePort
                   │
                   ▼
      Istio Ingress Gateway
                   │
                   ▼
          Istio Gateway
                   │
                   ▼
         Istio VirtualService
                   │
                   ▼
        Kubernetes Service
                   │
                   ▼
      httpbin Pod + Envoy Sidecar
```

## Prerequisites

- Kubernetes cluster
- `kubectl`
- `istioctl`
- NGINX installed on the control-plane or a reachable host

## Step 1 - Install Istio

Download Istio:

```bash
curl -L https://istio.io/downloadIstio | sh -
```

Move into the extracted directory:

```bash
cd istio-*
```

Add Istio binaries to your path:

```bash
export PATH=$PWD/bin:$PATH
```

Install Istio using the demo profile:

```bash
istioctl install --set profile=demo -y
```

Verify the control plane:

```bash
kubectl get pods -n istio-system
```

## Step 2 - Create Namespace

```bash
kubectl create namespace demo
kubectl label namespace demo istio-injection=enabled
```

Verify the label:

```bash
kubectl get ns --show-labels
```

## Step 3 - Deploy httpbin

Apply the application manifest:

```bash
kubectl apply -f manifests/app/httpbin.yaml
```

Verify the pod is running with the Istio sidecar:

```bash
kubectl get pods -n demo
```

Expected state:

```text
2/2 Running
```

## Step 4 - Verify the Service

Check the service port:

```bash
kubectl get svc -n demo
```

The `httpbin` service should expose port `80`.

## Step 5 - Install and Configure NGINX

Install NGINX:

```bash
sudo apt update
sudo apt install nginx -y
```

Edit the default site:

```bash
sudo nano /etc/nginx/sites-available/default
```

Use this configuration:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://172.30.1.2:32271;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Validate and restart NGINX:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

## Step 6 - Create the Istio Gateway

Create `manifests/gateway/gateway.yaml`:

```yaml
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: demo
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

Apply it:

```bash
kubectl apply -f manifests/gateway/gateway.yaml
```

## Step 7 - Create the VirtualService

Create `manifests/gateway/virtualservice.yaml`:

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
  namespace: demo
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: httpbin
        port:
          number: 80
```

Apply it:

```bash
kubectl apply -f manifests/gateway/virtualservice.yaml
```

## Step 8 - Test the Istio Ingress Gateway

The Istio ingress gateway is still of type `LoadBalancer`, but in this lab the external IP remains pending because no cloud load balancer or MetalLB is attached. The service still exposes NodePorts, including HTTP on `32271`.

Test directly against the ingress gateway NodePort:

```bash
curl -v http://172.30.1.2:32271/get
```

Expected:

- `HTTP/1.1 200 OK`
- `server: istio-envoy`

## Step 9 - Test Through NGINX

Now test through NGINX:

```bash
curl -v http://172.30.1.2/get
```

Expected:

- `HTTP/1.1 200 OK`
- `Server: nginx`
- `x-envoy-upstream-service-time`

This proves the traffic flow is working end to end.

## Request Flow

```text
Client
  │
  ▼
NGINX Reverse Proxy
  │
  ▼
NodePort 32271
  │
  ▼
Istio Ingress Gateway
  │
  ▼
Gateway
  │
  ▼
VirtualService
  │
  ▼
httpbin Service
  │
  ▼
httpbin Pod + Envoy Sidecar
```

## Why EXTERNAL-IP is Pending

The Istio ingress gateway service is still `LoadBalancer`, so Kubernetes waits for a load balancer to assign an external IP. In this Killercoda lab, NGINX forwards directly to the node IP and NodePort, so the pending external IP does not block traffic.

## Common Mistake

If the VirtualService routes to port `8000` while the service exposes port `80`, Istio returns `503 NC cluster_not_found`.

Use port `80` in the VirtualService destination.

## Next Labs

- DestinationRule
- Canary routing
- Blue/green deployment
- Retries and timeouts
- Fault injection
- mTLS
- AuthorizationPolicy
- Prometheus, Grafana, Kiali, Jaeger
