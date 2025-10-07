# Resource Allocation Overview for Kubernetes Laptop Server

This document summarizes estimated **resource allocation** for running a full Kubernetes stack on a single laptop node.

---

## 🧩 Stack Components
Includes:
- 2 separate namespaces (e.g. `infrastructures` and `services`)
- Python microservices (FastAPI)
- JWT authentication (Keycloak)
- HPA + health/ready probes
- Observability: Prometheus + Grafana + Loki + Jaeger
- NATS messaging
- Postgres + Redis
- Linkerd service mesh (mTLS, retries, circuit breaker)
- nginx-ingress + oauth2-proxy + mkcert TLS
- Tilt + Skaffold support

---

## ⚙️ Estimated Resource Allocation per Component

| Component | CPU (vCore) | Memory (GB) | Notes |
|------------|--------------|--------------|--------|
| **Kubernetes Control Plane (k3s/microk8s)** | 1–2 | 1–2 | Lightweight distribution recommended |
| **Prometheus** | 2–6 | 4–16 | RAM grows with time series count and retention duration |
| **Grafana** | 1 | 0.5–2 | Very light unless dashboards are complex |
| **Loki** | 1–2 | 2–4 | Depends on log volume; consider local disk or external storage |
| **Jaeger (Collector + Query)** | 1–2 | 1–4 | Trace retention increases resource demand |
| **Keycloak** | 2–4 | 2–4 | Needs JVM tuning; cache and sessions impact usage |
| **NATS** | 1 | 0.5–2 | Lightweight unless persistent messaging enabled |
| **Postgres** | 2 | 2–8 | Allocate NVMe storage for data and WAL |
| **Redis** | 1 | 0.5–4 | Based on cache size and persistence |
| **Linkerd (Data Plane Proxies)** | + per pod | 0.05–0.2 per sidecar | Multiplies by number of pods |
| **nginx-ingress + oauth2-proxy + mkcert** | 1 | 0.5–1 | TLS and proxy overhead minimal |

---

## 💾 Recommended Laptop Hardware Configurations

| Level | CPU Cores | RAM | Disk | Usage |
|-------|------------|-----|------|--------|
| **Minimum (Dev/Test)** | 6 cores | 32 GB | 1 TB NVMe | Development and CI light load |
| **Recommended (Stable 24/7)** | 8 cores | 48 GB | 1–2 TB NVMe | Small production / heavy observability |
| **Beefy (Full Observability)** | 12–16 cores | 64 GB | 2 TB NVMe | All components + long retention + multiple replicas |

---

## 🧠 Operational Recommendations

1. Use **Linux (Ubuntu/Fedora Server)** for stable 24/7 operation.  
2. Prefer **k3s** or **microk8s** for lightweight deployment.  
3. Isolate storage for Prometheus and Postgres.  
4. Limit retention (Prometheus, Jaeger, Loki) to keep memory usage low.  
5. Use **wired Ethernet**; avoid Wi-Fi for critical services.  
6. Backup data periodically and enable VM snapshots.  
7. Manage **Linkerd auto-injection scope** to reduce sidecar overhead.  
8. Ensure cooling and UPS power stability for continuous uptime.  

---

## 🔍 Summary

For a single-node laptop-based Kubernetes cluster with observability and service mesh enabled:
- Allocate **at least 32 GB RAM** (48–64 GB ideal)
- Use **NVMe storage**
- CPU with **8–12 cores** recommended
- Consider **k3s/microk8s** instead of full kubeadm for local environment

Prometheus and Linkerd are the heaviest components in resource consumption.

