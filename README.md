# Application Microservices Deployment Guide (`application` branch)

This repository branch contains the complete source code, Docker configurations, and CI/CD deployment pipelines for a multi-service Python Web Application designed to run seamlessly on AWS ECS (Fargate) and AWS EKS clusters.

---

## 🏗️ Application Architecture & Directory Structure

The application consists of two decoupled microservices and a relational database:

```text
.
├── backend/                  # Python FastAPI REST API Microservice (Port 8000)
│   ├── app/
│   │   ├── database.py       # SQLAlchemy Database Engine (PostgreSQL / SQLite fallback)
│   │   ├── models.py         # DB Models (Users, Products, Orders)
│   │   ├── schemas.py        # Pydantic Schemas & Data Validation
│   │   └── main.py           # FastAPI Endpoints & Health Checks
│   ├── Dockerfile            # Standalone Backend Dockerfile
│   └── requirements.txt
│
├── frontend/                 # Python Flask Web Portal & UI (Port 5000)
│   ├── app.py                # Flask Router & Backend API Client
│   ├── static/css/style.css  # Modern Glassmorphism & Dark Mode Styling
│   ├── templates/            # HTML Views (Dashboard, Users, Products, Orders)
│   ├── Dockerfile            # Standalone Frontend Dockerfile
│   └── requirements.txt
│
├── db/                       # Database Initialization
│   └── init.sql              # PostgreSQL Schema Creation & Seed Data
│
├── docker-compose.yml        # Local Multi-Container Orchestration
└── .github/workflows/
    └── deploy-app.yml        # CI/CD Pipeline (Build Docker -> Push ECR -> Deploy AWS)
```

---

## 🔌 Service Connectivity & Inter-Communication

The services are decoupled and communicate over standard HTTP REST APIs using environment variables:

```text
┌─────────────────────────┐          HTTP REST API          ┌─────────────────────────┐          SQL Connection         ┌─────────────────────────┐
│    Frontend Service     │ ──────────────────────────────> │     Backend Service     │ ──────────────────────────────> │    Database / Storage   │
│  (Port 5000 / Python)   │   BACKEND_URL=http://api:8000   │  (Port 8000 / FastAPI)  │   DB_HOST=db.example.com    │   (PostgreSQL / RDS)    │
└─────────────────────────┘                                 └─────────────────────────┘                                 └─────────────────────────┘
```

1. **Frontend $\rightarrow$ Backend**:
   - Configured via **`BACKEND_URL`** (default: `http://backend:8000`).
   - On AWS ECS / Public IP: Set `BACKEND_URL="http://<BACKEND_PUBLIC_IP>:8000"`.
   - On AWS EKS: Set `BACKEND_URL="http://backend-service:8000"` (Kubernetes Service DNS).

2. **Backend $\rightarrow$ Database**:
   - Configured via `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.
   - **Fallback Mode**: If `USE_SQLITE=true` is set, the backend runs 100% standalone using an embedded SQLite database without needing external DB setup.

---

## 🛠️ Building & Running Images Separately (Without Docker Compose)

You can build and run each service independently using standard Docker commands:

### Step 1: Build the Container Images Separately

```bash
# Build Backend Image
docker build -t cloud-backend ./backend

# Build Frontend Image
docker build -t cloud-frontend ./frontend
```

### Step 2: Run Services on a Docker Bridge Network

```bash
# 1. Create a custom docker bridge network
docker network create cloud-net

# 2. Run Backend container (using internal SQLite DB fallback for simplicity)
docker run -d --name backend \
  --network cloud-net \
  -p 8000:8000 \
  -e USE_SQLITE=true \
  cloud-backend

# 3. Run Frontend container (connects to backend via container name)
docker run -d --name frontend \
  --network cloud-net \
  -p 5000:5000 \
  -e BACKEND_URL="http://backend:8000" \
  cloud-frontend
```

### Step 3: Access the Applications

- **Frontend Portal**: Navigate to `http://localhost:5000`
- **Backend API Docs**: Navigate to `http://localhost:8000/docs` (Swagger UI)
- **Backend Healthcheck**: `http://localhost:8000/api/health`

---

## 🚀 Local Run using Docker Compose

To launch all 3 services (PostgreSQL, Backend API, Frontend Web App) together with one command:

```bash
docker-compose up --build
```

---

## 📦 CI/CD Pipeline (`deploy-app.yml`)

The GitHub Actions workflow [`.github/workflows/deploy-app.yml`](.github/workflows/deploy-app.yml) automates the build and deployment process.

### Pipeline Workflow:
1. **Trigger**:
   - Push to `application` branch (when changes occur in `backend/` or `frontend/`).
   - Manual trigger (`workflow_dispatch`) with parameters for target `environment` (`dev`, `stage`, `prod`) and `service` (`all`, `frontend`, `backend`).
2. **Build & Tag**:
   - Builds Docker images for `frontend` and `backend` separately.
   - Tags images with Git commit SHA (`${GITHUB_SHA::7}`) and `latest`.
3. **Push to Amazon ECR**:
   - Authenticates to AWS ECR via `aws-actions/amazon-ecr-login`.
   - Pushes separate container images to dedicated ECR repositories.
4. **Deploy**:
   - Triggers deployment update to target AWS ECS / EKS infrastructure.

---

## 🔐 Required GitHub Secrets for CI/CD

Add the following secrets to your GitHub Repository (**Settings > Secrets and variables > Actions**):

| Secret Name | Description | Example / Default |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | AWS IAM Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | Target AWS Region | `us-east-1` |
| `ECR_FRONTEND_REPO` | Amazon ECR Repo for Frontend | `istio-baremetal-k8s-dev-frontend` |
| `ECR_BACKEND_REPO` | Amazon ECR Repo for Backend | `istio-baremetal-k8s-dev-backend` |