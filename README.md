# istio-baremetal-k8s
istio-baremetal-k8s-lab

## Using GitHub Container Registry (GHCR)

This guide demonstrates how to use GitHub Container Registry for storing and deploying Docker images in your Kubernetes cluster.

### Prerequisites
- GitHub Account
- GitHub Personal Access Token (PAT) with `write:packages` permission
- Docker installed locally

### Step 1: Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with scopes:
   - `write:packages` - Push container images
   - `read:packages` - Pull container images
   - `delete:packages` - Delete container images (optional)
3. Copy and save your token

### Step 2: Authenticate Docker with GHCR

```bash
echo $GITHUB_PAT | docker login ghcr.io -u venky913381 --password-stdin
```

### Step 3: Build and Push Docker Image

```bash
# Build your Docker image
docker build -t ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest .

# Push to GHCR
docker push ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest
```

### Step 4: Create Kubernetes Image Pull Secret

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=venky913381 \
  --docker-password=$GITHUB_PAT \
  --docker-email=your-email@example.com \
  -n demo
```

Or apply the pre-configured secret manifest:

```bash
kubectl apply -f manifests/ghcr-secret.yaml
```

### Step 5: Apply Manifests

```bash
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/ghcr-secret.yaml
kubectl apply -f manifests/httpbin.yaml
kubectl apply -f manifests/gateway.yaml
```

### Step 6: Verify Deployment

```bash
kubectl get pods -n demo
kubectl get svc -n demo
```

### GHCR Image URL Format
- Registry: `ghcr.io`
- Username: `venky913381` (GitHub username)
- Repository: `istio-baremetal-k8s` (your repo name)
- Image: `httpbin` (the image name)
- Full URL: `ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest`

### Making Package Public (Optional)

To make your package publicly available:
1. Go to your repository → Packages
2. Select the package
3. Click Package settings
4. Change visibility to Public

### Troubleshooting

- **ImagePullBackOff**: Verify the secret exists and credentials are correct
- **401 Unauthorized**: Check your GitHub PAT has `write:packages` and `read:packages` scopes
- **Cannot find image**: Ensure the image is pushed to GHCR with the correct tag

### Next Labs

- DestinationRule
- Canary routing
- Blue/green deployment
- Retries and timeouts
- Fault injection
- mTLS
- AuthorizationPolicy
- Prometheus, Grafana, Kiali, Jaeger
