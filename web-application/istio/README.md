# Istio configuration for web-app

This folder contains optional Istio configuration files for the `web-app` application and instructions to apply them.

Files included:
- `peerauthentication.yaml` — enable strict mTLS for the `web-app` namespace.
- `destinationrule-mtls.yaml` — DestinationRule to configure ISTIO_MUTUAL TLS for the `web-app` service.
- `virtualservice-retries.yaml` — VirtualService for the web-app with retry and timeout policy.

Use these files when you want to enable Istio security (mTLS) and basic traffic policies for `web-app`.

Quick apply (order matters when enabling mTLS):

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
