# istio-baremetal-k8s
istio-baremetal-k8s-lab

## Using GitHub Container Registry (GHCR)

This guide demonstrates how to use GitHub Container Registry for storing and deploying Docker images in your Kubernetes cluster.

### Prerequisites
- GitHub Account with repository access
- Docker installed locally
- `kubectl` and `istioctl` installed
- Bare-metal Kubernetes cluster running

### Step 1: Enable Public Access to Package

1. Go to GitHub → Your Repository → Packages
2. Find your `httpbin` package
3. Click on the package → Click "Package settings" (gear icon)
4. Change visibility from "Private" to "Public"
5. Click "Change visibility"

> **Note**: Public packages don't require authentication to pull

### Step 2: Authenticate Docker with GHCR (Required for Pushing)

Create a GitHub Personal Access Token:
1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Name it: `GHCR_TOKEN`
4. Select scopes:
   - ☑️ `write:packages` - Push container images
   - ☑️ `read:packages` - Pull container images
   - ☑️ `delete:packages` - Delete container images (optional)
5. Click "Generate token"
6. Copy the token (you won't see it again!)

**Login to GHCR:**

```bash
export GITHUB_PAT="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
echo $GITHUB_PAT | docker login ghcr.io -u venky913381 --password-stdin
```

Expected output:
```
Login Succeeded
```

> **Common Error Fix**: If you get `denied: requested access to the resource is denied`, it means:
> - Your token is invalid or expired
> - Your token doesn't have `write:packages` scope
> - You're not logged in to the correct registry (should be `ghcr.io`, not `docker.io`)

### Step 3: Build Docker Image Locally

Clone your repository:
```bash
git clone https://github.com/venky913381/istio-baremetal-k8s.git
cd istio-baremetal-k8s
```

Build the Docker image:
```bash
docker build -t ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest -f nginx-proxy/Dockerfile nginx-proxy/
```

> **Note**: If you don't have a Dockerfile yet, you can use the public httpbin image directly

### Step 4: Push Docker Image to GHCR

Push your image to GitHub Container Registry:
```bash
docker push ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest
```

Expected output:
```
The push refers to repository [ghcr.io/venky913381/istio-baremetal-k8s/httpbin]
f9577bb2abcb: Pushed
41e71b16b4fd: Pushed
119acd70b026: Pushed
latest: digest: sha256:abc123... size: 1234
```

> **Troubleshooting Push Errors**:
> - `denied: requested access to the resource is denied` → Re-login: `docker logout ghcr.io && docker login ghcr.io`
> - `authentication required` → Verify token has `write:packages` scope
> - `name unknown` → Use lowercase username: `ghcr.io/venky913381/...`

Verify the image was pushed:
```bash
docker pull ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest
```

### Step 5: Make Package Public (Optional for Public Images)

To allow anyone to pull without authentication:
1. Go to GitHub → Packages → Select `httpbin`
2. Click "Package settings" (⚙️ icon)
3. Scroll to "Danger Zone" → "Change package visibility"
4. Select "Public"
5. Confirm

Now anyone can pull:
```bash
docker pull ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest
```

### Step 6: Deploy to Kubernetes Cluster

Navigate to the manifest directory:
```bash
cd nginx-proxy/manifests
```

Create the namespace and label it for Istio injection:
```bash
kubectl apply -f namespace.yaml
```

Verify namespace:
```bash
kubectl get ns --show-labels
```

**For PUBLIC images** (no secret needed):
```bash
kubectl apply -f httpbin.yaml
kubectl apply -f gateway.yaml
```

**For PRIVATE images** (secret required):

Create the image pull secret:
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=venky913381 \
  --docker-password=$GITHUB_PAT \
  --docker-email=your-email@example.com \
  -n demo
```

Then apply:
```bash
kubectl apply -f ghcr-secret.yaml
kubectl apply -f httpbin.yaml
kubectl apply -f gateway.yaml
```

### Step 7: Verify Deployment

Check if pods are running:
```bash
kubectl get pods -n demo
```

Expected output:
```
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-xxxxx             2/2     Running   0          10s
```

Check services:
```bash
kubectl get svc -n demo
```

Check Istio ingress gateway:
```bash
kubectl get svc -n istio-system | grep ingress-gateway
```

### Step 8: Test the Application

Get the ingress gateway NodePort:
```bash
kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
```

Get any node IP:
```bash
kubectl get nodes -o wide
```

Test the application:
```bash
curl -v http://<NODE_IP>:<NODEPORT>/get
```

Example:
```bash
curl -v http://192.168.1.100:31234/get
```

### GHCR Image URL Format
- Registry: `ghcr.io`
- Username: `venky913381` (GitHub username)
- Repository: `istio-baremetal-k8s` (your repo name)
- Image: `httpbin` (the image name)
- Tag: `latest` (version tag)
- **Full URL**: `ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest`

### Complete Local Setup Commands (Quick Reference)

```bash
# 1. Set GitHub PAT
export GITHUB_PAT="your_token_here"

# 2. Login to GHCR
echo $GITHUB_PAT | docker login ghcr.io -u venky913381 --password-stdin

# 3. Build image
docker build -t ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest -f nginx-proxy/Dockerfile nginx-proxy/

# 4. Push to GHCR
docker push ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest

# 5. Deploy to K8s
kubectl apply -f nginx-proxy/manifests/namespace.yaml
kubectl apply -f nginx-proxy/manifests/httpbin.yaml
kubectl apply -f nginx-proxy/manifests/gateway.yaml

# 6. Verify
kubectl get pods -n demo
```

### Troubleshooting

**Push Error: denied: requested access to the resource is denied**
```bash
# Re-authenticate
docker logout ghcr.io
echo $GITHUB_PAT | docker login ghcr.io -u venky913381 --password-stdin

# Verify token
echo $GITHUB_PAT
# Should output: ghp_xxxxxx...
```

**ImagePullBackOff in Kubernetes**
```bash
# Check pod logs
kubectl describe pod -n demo <pod-name>

# View events
kubectl get events -n demo --sort-by='.lastTimestamp'

# If using private image, verify secret exists
kubectl get secrets -n demo
```

**401 Unauthorized when pushing**
- Your PAT token is invalid, expired, or lacks `write:packages` scope
- Generate a new token with correct scopes

**Cannot find image (pull error)**
- Verify image was pushed: `docker images | grep httpbin`
- Check package visibility is Public (if not creating secret)
- Verify correct image URL in deployment manifest

**Pod still in ImagePullBackOff**
```bash
# Force pod restart
kubectl rollout restart deployment/httpbin -n demo

# Check again
kubectl get pods -n demo
```

### Useful Commands

Update image version:
```bash
kubectl set image deployment/httpbin -n demo \
  httpbin=ghcr.io/venky913381/istio-baremetal-k8s/httpbin:v1.0.0
```

View pod logs:
```bash
kubectl logs -n demo <pod-name> -c httpbin
```

Port forward to test locally:
```bash
kubectl port-forward -n demo svc/httpbin 8080:80
curl http://localhost:8080/get
```

View all images in GHCR:
```bash
curl -H "Authorization: token $GITHUB_PAT" \
  https://api.github.com/user/packages?package_type=container
```

### Next Labs

- DestinationRule
- Canary routing
- Blue/green deployment
- Retries and timeouts
- Fault injection
- mTLS
- AuthorizationPolicy
- Prometheus, Grafana, Kiali, Jaeger
