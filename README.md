# Skybyte DevOps Deployment — DevOps Engineering Challenge

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)

---

## 📌 Project Overview

This repository is my solution to the **Skybyte DevOps Engineering Challenge: Inherit & Harden**. I was handed a deliberately broken work-in-progress repository — a containerized Python service deployed via Helm into Kubernetes, with Terraform infrastructure management and a GitHub Actions CI pipeline — and tasked with auditing, hardening, and shipping it within 48 hours.

The original codebase had real-world production defects: a Dockerfile building as root, missing resource limits, misconfigured health probes, a secret in plain text, a broken Helm chart, and a CI pipeline that reported green while validating almost nothing. This repo documents every defect found and every fix applied.

| Component | Technology |
|---|---|
| Application | Python (Flask-based, port 80) |
| Containerization | Docker (`python:3.9-slim`, non-root `appuser`) |
| Kubernetes Deployment | Helm 3.x (`helm/skybyte-app/`) |
| Infrastructure | Terraform (namespace, ResourceQuota, secrets) |
| CI/CD | GitHub Actions (`.github/workflows/`) |
| Policy Enforcement | Kyverno (`policies/`) |
| Local Cluster | Minikube / Kind |

---

## 🔍 What Was Wrong (Summary)

The inherited starter repo had the following categories of defects, fully documented in [`AUDIT.md`](AUDIT.md):

**Security** — Dockerfile ran as root before the non-root user switch; secret stored in plain text in Helm values; no `securityContext` (`readOnlyRootFilesystem`, `allowPrivilegeEscalation`, `capabilities`) defined in the deployment.

**Reliability** — Health probes misconfigured (wrong paths/thresholds); no `resources.requests` or `resources.limits` set on containers; no graceful SIGTERM handling, meaning in-flight requests could be dropped on pod termination.

**Hygiene** — CI pipeline ran `helm lint` and `terraform validate` steps that were either skipped or non-blocking; Docker image used unpinned `:latest`-style tags; no image vulnerability scanning.

**Documentation** — README described a setup that diverged from actual code; `setup.sh` had broken steps that exited silently on failure.

---

## ✨ What I Fixed

### Security Hardening
- Container now runs as non-root (`appuser`, UID 1000) with `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, dropped `ALL` capabilities, and a `RuntimeDefault` seccomp profile
- Secret moved out of Helm values into a Kubernetes `Secret` resource managed via Terraform
- Docker base image pinned to a specific digest (`python:3.9-slim@sha256:...`)

### Reliability
- `livenessProbe` and `readinessProbe` both wired to `/healthz` with sensible `initialDelaySeconds`, `periodSeconds`, and `failureThreshold` values
- `resources.requests` and `resources.limits` defined for CPU and memory
- SIGTERM handled gracefully — the app stops accepting new requests, drains in-flight ones, and exits within `terminationGracePeriodSeconds`

### Observability
- `/metrics` endpoint added exposing `http_requests_total` (with `method`, `path`, `status` labels) and a request duration histogram
- Prometheus scrape annotations added to the Service

### Policy as Code (Kyverno)
- **Policy 1** — Enforce non-root containers in the `devops-challenge` namespace
- **Policy 2** — Require resource requests on all containers (catches the original missing limits defect)

### CI Pipeline
- Replaced the original broken workflow with a fully validated pipeline (see below)

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                  GitHub Actions CI                   │
│  lint → test → helm lint+kubeconform → tf validate   │
│  → docker buildx (amd64+arm64) → trivy scan          │
│  → kyverno apply (policy check)                      │
└──────────────────────────┬───────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│              Kubernetes (Minikube / Kind)             │
│                                                      │
│  Namespace: devops-challenge  (via Terraform)        │
│  ResourceQuota             (via Terraform)           │
│  Secret                    (via Terraform)           │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │  Helm Chart: skybyte-app                    │    │
│  │                                             │    │
│  │  Deployment → Pod (appuser:80)              │    │
│  │    ├── /           → {"message":"Hello..."}  │    │
│  │    ├── /healthz    → liveness + readiness   │    │
│  │    └── /metrics    → Prometheus metrics     │    │
│  │                                             │    │
│  │  Service (ClusterIP :80)                    │    │
│  └─────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
skybyte-devops-deployment/
├── app/                        # Python service (main.py, requirements.txt)
├── helm/skybyte-app/           # Helm chart for Kubernetes deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ...
├── terraform/                  # Namespace + ResourceQuota + Secret
├── policies/                   # Kyverno policies (NEW)
│   ├── no-root-containers.yaml
│   └── require-resource-requests.yaml
├── .github/workflows/
│   └── ci.yml                  # Hardened CI pipeline
├── Dockerfile                  # python:3.9-slim, non-root appuser, port 80
├── setup.sh                    # Idempotent: build → terraform → helm install
├── system-checks.sh            # NEW — verifies non-root, probes, metrics, recovery
├── AUDIT.md                    # NEW — full defect list with fixes
├── DECISIONS.md                # NEW — 8+ architectural decisions with rationale
├── CHALLENGE.md                # Original challenge brief
├── skybyte-output.png          # App running screenshot
├── skybyte-output-pipeline.png # CI pipeline screenshot
├── skybyte-output-terminal.png # Terminal output screenshot
└── README.md
```

---

## 🚀 Prerequisites

Tested against:

- Docker Desktop 4.x (or any Docker Engine 24+)
- Minikube v1.32+ **or** Kind v0.22+
- Helm 3.14+
- Terraform 1.7+
- Python 3.9+
- kubectl 1.29+

---

## ⚡ Quick Start

```bash
git clone https://github.com/Petchimuthu19/skybyte-devops-deployment.git
cd skybyte-devops-deployment
./setup.sh
```

`setup.sh` is idempotent — running it twice will not break anything. It will:
1. Build the Docker image
2. Run `terraform apply` (namespace, ResourceQuota, Secret)
3. Run `helm upgrade --install skybyte-app helm/skybyte-app/`

### Verify the Deployment

```bash
kubectl -n devops-challenge get pods
kubectl -n devops-challenge port-forward svc/skybyte-app 8080:80

# In a second terminal:
curl http://localhost:8080/
# Expected: {"message": "Hello, Candidate", "version": "1.0.0"}

curl http://localhost:8080/healthz
# Expected: {"status": "ok"}

curl http://localhost:8080/metrics
# Expected: Prometheus metrics including http_requests_total
```

---

## 🔁 GitHub Actions CI Pipeline

The original CI claimed to validate but largely did not. The replacement pipeline runs the following on every push:

| Step | Tool | What it validates |
|---|---|---|
| Python lint | `ruff` | Code style and syntax |
| Python tests | `pytest` | Unit tests incl. `/metrics` endpoint |
| Helm lint | `helm lint` | Chart structure and values consistency |
| Manifest validation | `helm template \| kubeconform` | Rendered manifests against K8s schema |
| Terraform fmt | `terraform fmt -check` | HCL formatting |
| Terraform validate | `terraform validate` | Configuration correctness |
| Docker build | `docker buildx` | Multi-arch build (amd64 + arm64) |
| Image scan | `trivy fs` + `trivy image` | Fails on HIGH/CRITICAL CVEs |
| Policy check | `kyverno apply` | Kyverno policies against rendered manifests |

---

## 📊 SLO Statement

> 99% of requests to `/` complete in under **200ms** over a rolling 7-day window.

This is defensible for this application because the handler does no I/O — it returns a static JSON response. A p99 > 200ms would indicate container resource starvation (CPU throttling from too-tight limits) or node-level pressure. This would be detected via the `http_request_duration_seconds` histogram exposed at `/metrics`, alerting when the `le="0.2"` bucket drops below 0.99 of total requests.

---

## 🧪 System Checks

`system-checks.sh` automates end-to-end verification:

```bash
./system-checks.sh
```

It will:
1. Print the in-container UID (proves non-root)
2. Print the bound port and capabilities
3. Curl `/` and validate the response body matches `{"message": "Hello, Candidate", "version": "1.0.0"}`
4. Curl `/metrics` and grep for `http_requests_total`
5. Kill the running pod (`kubectl delete pod`) and verify the Deployment recovers within 30s with no failed health checks during rollout

---

## 🛡️ Kyverno Policies

Both policies live in `policies/` and are applied during `helm install` / `terraform apply`.

**Policy 1 — No Root Containers** (`no-root-containers.yaml`)
Enforces that no container in the `devops-challenge` namespace runs as UID 0. This would have caught the original Dockerfile before the `USER appuser` switch was added.

**Policy 2 — Require Resource Requests** (`require-resource-requests.yaml`)
Enforces that all containers declare `resources.requests.cpu` and `resources.requests.memory`. This catches the original missing limits defect that would cause unbounded resource consumption in production.

Both policies are also validated in CI via `kyverno apply` against the rendered Helm manifests. See `DECISIONS.md` for why Kyverno was chosen over Gatekeeper.

---

## 📸 Output Screenshots

| File | Description |
|---|---|
| `skybyte-output.png` | App responding at `localhost:8080` |
| `skybyte-output-pipeline.png` | GitHub Actions pipeline — all checks green |
| `skybyte-output-terminal.png` | Terminal output of `system-checks.sh` |

---

## 🔮 Things I Would Do Next (With Another Week)

- **External Secrets Operator** — Replace the Terraform-managed `kubernetes_secret` with ESO pulling from AWS Secrets Manager or HashiCorp Vault, so secrets never touch the Terraform state file.
- **Horizontal Pod Autoscaler** — Add HPA based on the `http_requests_total` rate metric, so the deployment scales automatically under load.
- **Multi-environment Helm values** — Add `values-staging.yaml` and `values-prod.yaml` to properly separate resource limits and replica counts per environment.
- **SBOM generation** — Add `syft` to CI to produce a software bill of materials alongside every image build, for supply chain compliance.
- **Alerting rules** — Add a `PrometheusRule` CRD wiring the SLO p99 metric to an Alertmanager notification so SLO breaches are caught automatically, not just observable in dashboards.
- **`asciinema` recording** — Record a full end-to-end demo of `setup.sh` + `system-checks.sh` on a clean Minikube for the live walkthrough.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit with meaningful messages explaining *why*, not just *what*
4. Push and open a Pull Request

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

> Inherited, hardened, and shipped. Every change is defensible — see [`DECISIONS.md`](DECISIONS.md).
