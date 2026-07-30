# Istio configuration for web-app

This folder contains optional Istio configuration files for the `web-app` application and instructions to apply them.

Files included:
- `peerauthentication.yaml` — enable strict mTLS for the `web-app` namespace.
- `destinationrule-mtls.yaml` — DestinationRule to configure ISTIO_MUTUAL TLS for the `web-app` service.
- `virtualservice-retries.yaml` — VirtualService for the web-app with retry and timeout policy.


## Install Istio and components

These steps install Istio locally and (optionally) the example addons (Prometheus, Grafana, Kiali, Jaeger). Run them from a machine with `kubectl` configured for your cluster.

1. Download Istio and add `istioctl` to your PATH:

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
```

2. Install Istio (demo profile) using `istioctl`:

```bash
istioctl install --set profile=demo -y
```

3. (Optional) Install the example addons (Prometheus, Grafana, Kiali, Jaeger):

```bash
# from inside the extracted istio directory
kubectl apply -f samples/addons
```

4. Verify the control plane and addons:

```bash
kubectl get pods -n istio-system
kubectl get svc -n istio-system
```

5. If you want automatic sidecar injection for the `web-app` namespace (recommended for this lab):

```bash
kubectl label namespace web-app istio-injection=enabled --overwrite
```

6. To inspect the ingress gateway service (to get NodePort/LoadBalancer info):

```bash
kubectl -n istio-system get svc istio-ingressgateway
# NodePort (if present):
kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}'
# External IP (if LoadBalancer is provisioned):
kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Notes:
- On bare-metal clusters the `istio-ingressgateway` service may remain of type `LoadBalancer` with a pending EXTERNAL-IP. In this lab we use an external NGINX (or host) to proxy to a node IP + NodePort (see the repo's `nginx-proxy` guide).
- For production use, choose an appropriate installation profile and follow Istio's best practices for control plane HA, telemetry, and security.


## Quick apply (order matters when enabling mTLS)

1. Make sure the namespace and application are created and running:

```bash
kubectl apply -f web-application/manifests/namespace.yaml
kubectl apply -f web-application/manifests/deployment.yaml
kubectl apply -f web-application/manifests/service.yaml
```

2. Apply DestinationRule and PeerAuthentication to enable mTLS for the service:

```bash
kubectl apply -f web-application/istio/destinationrule-mtls.yaml
kubectl apply -f web-application/istio/peerauthentication.yaml
```

3. Apply the VirtualService with retries/timeout (this replaces or complements the basic VirtualService in manifests):

```bash
kubectl apply -f web-application/istio/virtualservice-retries.yaml
```

4. Verify:

```bash
kubectl -n web-app get peerauthentication,destinationrule,virtualservice
kubectl -n web-app get pods -l app=web-app
kubectl -n web-app get svc web-app
```

Notes & troubleshooting
- Enabling strict mTLS may cause 503 errors if non-mesh (external) traffic reaches the service directly; use the Istio ingressgateway and DestinationRule to ensure mesh TLS when traffic is routed internally.
- If you prefer to disable mTLS for testing, delete the PeerAuthentication or set mode: PERMISSIVE.
- These are examples; adapt hostnames, subsets, and trafficPolicy to your environment.
