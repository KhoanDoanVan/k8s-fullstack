# K8s Full Stack Project

Production-ready Kubernetes project với đầy đủ observability, security và resilience.

## 📋 Prerequisites
- Docker Desktop hoặc Podman
- kubectl
- kind hoặc k3d
- Tilt hoặc Skaffold
- mkcert (cho TLS local)
- linkerd CLI
- make

## 🚀 Quick Start

### Option 1: kind + Tilt (Recommended)
```bash
make setup-kind
make deploy-tilt
```

### Option 2: k3d + Skaffold
```bash
make setup-k3d
make deploy-skaffold
```

### Option 3: Local Development (Docker Compose)
```bash
docker-compose up -d
cd services/api-service && uvicorn main:app --reload
cd services/worker-service && uvicorn main:app --port 8001 --reload
```

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| API Service | https://api.local | Via Keycloak |
| Grafana | https://grafana.local | Auto-login |
| Keycloak | http://keycloak.local | admin/admin |
| Prometheus | http://localhost:9090 | - |
| Jaeger | http://localhost:16686 | - |

## 🔐 Keycloak Setup

1. Truy cập http://keycloak.local
2. Login: admin/admin
3. Tạo Realm mới hoặc dùng master
4. Tạo Client:
   - Client ID: `k8s-client`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
   - Valid Redirect URIs: `http://oauth2-proxy.local/oauth2/callback`
   - Secret: `secret`
5. Tạo User và assign roles

## 📊 Architecture

```
┌─────────────────────────────────────────────────────┐
│                     Ingress Layer                    │
│  nginx-ingress + oauth2-proxy + mkcert TLS          │
└────────────────┬────────────────────────────────────┘
                 │
        ┌────────┴─────────┐
        │   Keycloak       │
        │   (Auth Server)  │
        └────────┬─────────┘
                 │
    ┌────────────┴────────────────┐
    │      Linkerd Service Mesh    │
    │  (mTLS, Retries, Circuit)    │
    └────────────┬────────────────┘
                 │
    ┌────────────┴────────────────┐
    │                              │
┌───▼─────┐              ┌────▼──────┐
│   API   │──────────────│  Worker   │
│ Service │   HTTP/NATS  │  Service  │
└────┬────┘              └─────┬─────┘
     │                         │
     ├──────┬──────┬──────────┤
     │      │      │           │
  ┌──▼──┐ ┌▼───┐ ┌▼────┐   ┌─▼────┐
  │Redis│ │PG  │ │NATS │   │Jaeger│
  └─────┘ └────┘ └─────┘   └──────┘
     │      │      │           │
     └──────┴──────┴───────────┘
                 │
        ┌────────┴─────────┐
        │   Observability   │
        │ Prometheus+Grafana│
        │   + Loki + Jaeger │
        └───────────────────┘
```

## 🎯 Components

### Infrastructure (namespace: infrastructures)
- **Database**: PostgreSQL 15 (StatefulSet)
- **Cache**: Redis 7
- **Message Queue**: NATS 2.10
- **Auth**: Keycloak 23.0 (OIDC/OAuth2)
- **Metrics**: Prometheus 2.48
- **Dashboards**: Grafana 10.2
- **Logs**: Loki 2.9 + Promtail
- **Tracing**: Jaeger 1.51 (all-in-one)

### Services (namespace: services)
- **API Service**: FastAPI + Python 3.11
  - JWT authentication
  - Distributed tracing
  - Metrics endpoint
  - Health/Ready probes
  - HPA (2-10 replicas)
  
- **Worker Service**: FastAPI + Python 3.11
  - NATS subscriber
  - Background processing
  - Circuit breaker via Linkerd

### Service Mesh (Linkerd)
- Automatic mTLS between services
- Retries: 3 attempts, exponential backoff
- Timeouts: 5s for POST, 10s for GET
- Circuit breaker patterns
- Authorization policies

### Ingress
- nginx-ingress controller
- oauth2-proxy for authentication
- mkcert for local TLS certificates
- Host-based routing

### Scaling & Resilience
- HPA: CPU-based autoscaling (70%)
- Liveness probes: /health endpoint
- Readiness probes: /ready endpoint
- Resource limits: CPU/Memory
- PodDisruptionBudgets (production)

## 🔧 Development Workflow

### Using Tilt
```bash
tilt up          # Start all services
tilt down        # Stop all services
tilt logs api-service  # View logs
```

### Using Skaffold
```bash
skaffold dev     # Development mode with hot reload
skaffold run     # One-time deployment
skaffold delete  # Clean up
```

### Manual Deployment
```bash
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/infrastructures/
kubectl apply -f k8s/services/
kubectl apply -f k8s/ingress/
kubectl apply -f k8s/linkerd/
```

## 📈 Monitoring

### Prometheus Queries
```promql
# Request rate
rate(api_requests_total[5m])

# P95 latency
histogram_quantile(0.95, api_request_duration_seconds_bucket)

# Error rate
rate(api_requests_total{status="500"}[5m])
```

### Grafana Dashboards
- Pre-configured Linkerd dashboard
- Service metrics dashboard
- Infrastructure monitoring

### Jaeger Tracing
- Distributed trace visualization
- Service dependency graph
- Performance bottleneck identification

## 🧪 Testing

### Health Check
```bash
curl https://api.local/health
```

### Authenticated Request
```bash
# Get token from Keycloak
TOKEN=$(curl -X POST http://keycloak.local/realms/master/protocol/openid-connect/token \
  -d "client_id=k8s-client" \
  -d "client_secret=secret" \
  -d "grant_type=password" \
  -d "username=user" \
  -d "password=pass" | jq -r .access_token)

# Call API
curl -H "Authorization: Bearer $TOKEN" https://api.local/api/data
```

### Load Testing
```bash
kubectl run -it --rm load-test --image=williamyeh/hey:latest --restart=Never -- \
  -z 30s -c 50 https://api.local/api/data
```

## 🧹 Cleanup
```bash
make clean
```

## 📝 File Structure
```
.
├── services/
│   ├── api-service/
│   │   ├── main.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── worker-service/
│       ├── main.py
│       ├── Dockerfile
│       └── requirements.txt
├── k8s/
│   ├── namespaces.yaml
│   ├── infrastructures/
│   │   ├── postgres.yaml
│   │   ├── redis.yaml
│   │   ├── nats.yaml
│   │   ├── keycloak.yaml
│   │   ├── prometheus.yaml
│   │   ├── grafana.yaml
│   │   ├── loki.yaml
│   │   ├── promtail.yaml
│   │   └── jaeger.yaml
│   ├── services/
│   │   ├── api-service.yaml
│   │   └── worker-service.yaml
│   ├── ingress/
│   │   ├── oauth2-proxy.yaml
│   │   └── ingress.yaml
│   └── linkerd/
│       ├── service-profile.yaml
│       └── authz-policy.yaml
├── Tiltfile
├── skaffold.yaml
├── k3d-config.yaml
├── kind-config.yaml
├── docker-compose.yaml
├── setup.sh
├── Makefile
├── RESOURCE_ALLOCATION_README.md
└── README.md
```

## 🎓 Learning Resources
- [Linkerd Documentation](https://linkerd.io/docs/)
- [NATS Documentation](https://docs.nats.io/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [OpenTelemetry Python](https://opentelemetry.io/docs/languages/python/)
