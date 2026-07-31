# istio-baremetal-k8s
istio-baremetal-k8s-lab

## Using GitHub Container Registry (GHCR)

This guide demonstrates how to use GitHub Container Registry for storing and deploying Docker images in your Kubernetes cluster.

### Prerequisites
- GitHub Account with repository access
- Docker installed locally
- `kubectl` and `istioctl` installed
- Bare-metal Kubernetes cluster running

### Step 1: Set Up GitHub Personal Access Token

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

**Export the token as environment variable:**

```bash
export GITHUB_PAT="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Verify it's set:
```bash
echo $GITHUB_PAT
```

### Step 2: Create Dockerfile (If You Don't Have One)

Create `nginx-proxy/Dockerfile`:

```dockerfile
FROM kennethreitz/httpbin:latest
EXPOSE 80
```

Or if building a custom application:

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 80
CMD ["python", "app.py"]
```

### Step 3: Build Docker Image Locally

Build the image with GHCR registry name:

```bash
docker build -t ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest nginx-proxy/
```

Verify image was built:
```bash
docker images | grep httpbin
```

Expected output:
```
ghcr.io/venky913381/istio-baremetal-k8s/httpbin   latest    abc123def456   2 minutes ago   150MB
```

### Step 4: Authenticate Docker with GHCR (Non-TTY Fix)

**For non-TTY environments** (like remote servers, CI/CD, or containers):

Option A - Using stdin redirection with docker config:
```bash
cat > ~/.docker/config.json << EOF
{
  "auths": {
    "ghcr.io": {
      "auth": "$(echo -n "venky913381:$GITHUB_PAT" | base64)"
    }
  }
}
EOF
```

Option B - Using docker login with --password flag:
```bash
docker login ghcr.io -u venky913381 -p "$GITHUB_PAT"
```

Option C - Direct credential file creation:
```bash
mkdir -p ~/.docker
echo "{\"auths\":{\"ghcr.io\":{\"auth\":\"$(echo -n venky913381:$GITHUB_PAT | base64)\"}}}" > ~/.docker/config.json
chmod 600 ~/.docker/config.json
```

**Verify authentication:**
```bash
docker pull ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest
```

If successful, you'll see:
```
latest: Pulling from venky913381/istio-baremetal-k8s/httpbin
...
Digest: sha256:abc123...
Status: Downloaded newer image
```

### Step 5: Push Docker Image to GHCR

Push your locally built image:

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

**Troubleshooting Push Errors:**

```bash
# Error: denied: requested access to the resource is denied
# Solution: Re-authenticate
docker login ghcr.io -u venky913381 -p "$GITHUB_PAT"
docker push ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest

# Error: image does not exist locally with the tag
# Solution: Build the image first
docker build -t ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest nginx-proxy/

# Error: cannot perform an interactive login from a non TTY device
# Solution: Use Option B or C above (non-TTY authentication)
docker login ghcr.io -u venky913381 -p "$GITHUB_PAT"
```

### Step 6: Make Package Public (Optional)

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

### Step 7: Deploy to Kubernetes Cluster

Navigate to manifest directory:
```bash
cd nginx-proxy/manifests
```

Create the namespace:
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

### Step 8: Verify Deployment

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

### Step 9: Test the Application

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

# 2. Build image locally
docker build -t ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest nginx-proxy/

# 3. Authenticate (non-TTY safe)
docker login ghcr.io -u venky913381 -p "$GITHUB_PAT"

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

**Error: cannot perform an interactive login from a non TTY device**
```bash
# Use flag-based authentication instead of stdin
docker login ghcr.io -u venky913381 -p "$GITHUB_PAT"
```

**Error: denied: requested access to the resource is denied**
```bash
# Re-authenticate
docker login ghcr.io -u venky913381 -p "$GITHUB_PAT"

# Verify token is set
echo $GITHUB_PAT

# Try push again
docker push ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest
```

**Error: image does not exist locally with the tag**
```bash
# Build the image first
docker build -t ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest nginx-proxy/

# Verify image exists
docker images | grep httpbin

# Then push
docker push ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest
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
- Verify token exists: `echo $GITHUB_PAT`
- Verify token has `write:packages` scope
- Re-authenticate: `docker login ghcr.io -u venky913381 -p "$GITHUB_PAT"`

**Cannot find image (pull error)**
- Verify image was pushed: `docker images | grep httpbin`
- Check package visibility is Public (if not using secret)
- Verify image URL in deployment: `ghcr.io/venky913381/istio-baremetal-k8s/httpbin:latest`

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

View Docker login config:
```bash
cat ~/.docker/config.json
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
