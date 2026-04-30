# Homelab Kubernetes Cluster

A fully GitOps-managed Kubernetes homelab running on Proxmox with Talos Linux, provisioned via Terraform and orchestrated by ArgoCD.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          Kubernetes Cluster (Talos v1.9.2 / K8s v1.32.0)           │
│                                                                                     │
│  ┌─────────────────────────┐ ┌─────────────────────────┐ ┌───────────────────────┐  │
│  │  hp-gpu (Proxmox)       │ │  hp-z-server-a (Proxmox)│ │ hp-z-server-b (Proxmox│  │
│  │                         │ │                         │ │                       │  │
│  │  ┌───────────────────┐  │ │  ┌───────────────────┐  │ │ ┌───────────────────┐ │  │
│  │  │ talos-master-00   │  │ │  │ talos-master-01   │  │ │ │ talos-master-02   │ │  │
│  │  │ 10.30.0.10  32 GB │  │ │  │ 10.30.0.11  32 GB │  │ │ │ 10.30.0.12  32 GB │ │  │
│  │  └───────────────────┘  │ │  └───────────────────┘  │ │ └───────────────────┘ │  │
│  │  ┌───────────────────┐  │ │  ┌───────────────────┐  │ │ ┌───────────────────┐ │  │
│  │  │ talos-worker-00   │  │ │  │ talos-worker-02   │  │ │ │ talos-worker-06   │ │  │
│  │  │ 10.30.0.20  64 GB │  │ │  │ 10.30.0.22  32 GB │  │ │ │ 10.30.0.26  24 GB │ │  │
│  │  └───────────────────┘  │ │  └───────────────────┘  │ │ └───────────────────┘ │  │
│  │  ┌───────────────────┐  │ │                         │ │                       │  │
│  │  │ talos-worker-01   │  │ │                         │ │                       │  │
│  │  │ 10.30.0.21  64 GB │  │ │                         │ │                       │  │
│  │  └───────────────────┘  │ │                         │ │                       │  │
│  └─────────────────────────┘ └─────────────────────────┘ └───────────────────────┘  │
│                                                                                     │
│  Cluster VIP: 10.30.0.5          LB Range: 10.30.0.50-100                          │
│  Domain: *.homelab.home           Gateway: 10.30.0.1                                │
│                                                                                     │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────────────────────┐  │
│  │ Networking   │ │ GitOps       │ │ Storage      │ │ Security                    │  │
│  │             │ │              │ │              │ │                             │  │
│  │ MetalLB     │ │ ArgoCD       │ │ OpenEBS      │ │ Falco ──(json)──> Wazuh    │  │
│  │ Envoy GW    │ │ Image Updater│ │ Docker Reg   │ │ cert-manager                │  │
│  └─────────────┘ └──────────────┘ │ NFS          │ │ trust-manager               │  │
│                                   └──────────────┘ └─────────────────────────────┘  │
│  ┌──────────────────────┐ ┌──────────────┐ ┌──────────────────────────────────────┐  │
│  │ Observability        │ │ Data         │ │ Applications                         │  │
│  │                      │ │              │ │                                      │  │
│  │ Prometheus + Grafana │ │ CloudNativePG│ │ Media Server   AdGuard   Homebridge  │  │
│  │ OpenTelemetry   VPA  │ │              │ │ OpenClaw Operator                    │  │
│  └──────────────────────┘ └──────────────┘ └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────────────────┐
    │ Infrastructure as Code                                                       │
    │                                                                              │
    │  Packer ──> VM Templates ──> Terraform ──> Proxmox VMs ──> Talos Bootstrap  │
    │                                                                              │
    │  SOPS + AWS KMS ──> Encrypted Secrets ──> ArgoCD helm-secrets               │
    │                                                                              │
    │  Git Push ──> ArgoCD App of Apps ──> 29 Addon Charts ──> Auto Sync          │
    └──────────────────────────────────────────────────────────────────────────────┘
```

## Stack

### Infrastructure

| Component | Version | Description |
|-----------|---------|-------------|
| Proxmox VE | - | Hypervisor across 3 physical servers |
| Talos Linux | v1.9.2 | Immutable, API-managed Kubernetes OS |
| Kubernetes | v1.32.0 | Container orchestration |
| Packer | - | Builds Talos VM templates for Proxmox |
| Terraform | - | Provisions VMs, configures Talos, bootstraps cluster |

### Networking

| Component | Version | Description |
|-----------|---------|-------------|
| MetalLB | v0.14.9 | Bare-metal LoadBalancer (kustomize) |
| Envoy Gateway | v1.2.0 | Kubernetes Gateway API controller |

### GitOps

| Component | Version | Description |
|-----------|---------|-------------|
| ArgoCD | 9.4.10 | GitOps continuous delivery |
| ArgoCD Image Updater | - | Automated container image updates |

### Storage

| Component | Version | Description |
|-----------|---------|-------------|
| OpenEBS Mayastor | 4.1.1 | Replicated block storage across workers |
| Docker Registry | 2.2.3 | Private container image registry |
| NFS | - | Synology NAS for media storage |

### Security

| Component | Version | Description |
|-----------|---------|-------------|
| Falco | 8.0.2 (0.43.1) | Runtime syscall detection via eBPF |
| Wazuh | 1.0.22 (4.14.1) | SIEM/XDR - ingests Falco alerts |
| cert-manager | 1.16.3 | Automated TLS certificates |
| trust-manager | - | CA bundle distribution |

### Observability

| Component | Version | Description |
|-----------|---------|-------------|
| Kube Prometheus Stack | 58.2.1 | Prometheus, Grafana, Alertmanager |
| OpenTelemetry Operator | - | Collector lifecycle management |
| VPA | 3.0.1 | Vertical Pod Autoscaler |

### Data & Applications

| Component | Version | Description |
|-----------|---------|-------------|
| CloudNativePG | 0.27.1 | PostgreSQL operator |
| Media Server Operator | - | Media library management |
| AdGuard | v0.107.28 | DNS-level ad blocking |
| OpenClaw Operator | 0.17.0 | Custom operator |
| Homebridge | - | Apple HomeKit bridge |

## Repository Structure

```
homelab/
├── addons/                  # 29 addon Helm charts, each wrapping an upstream chart
│   ├── argocd/              #   Chart.yaml (dependency) + values.yaml (overrides)
│   ├── falco/               #   Some addons have custom templates/ (e.g. HTTPRoute)
│   ├── wazuh/
│   └── ...
├── chart/                   # App of Apps umbrella chart
│   ├── values.yaml          #   Central toggle: enable/disable each addon
│   └── templates/           #   One ArgoCD Application manifest per addon
├── config/
│   ├── secrets/             # SOPS-encrypted secrets (AWS KMS)
│   └── vars/                # Cluster config: node IPs, versions, domains
├── proxmox-talos/           # Terraform: Proxmox VMs + Talos config
│   ├── modules/             #   master-node/ and worker-node/ modules
│   └── bootstrap/           #   ArgoCD bootstrap Application + AppProject
├── packer/                  # Talos + Ubuntu VM template builders
├── databases/               # Database Terraform configs
└── modules/                 # Shared Terraform modules
```

## How It Works

### Deployment Flow

```
  Packer                Terraform              ArgoCD
    │                      │                      │
    ▼                      ▼                      ▼
 Build VM           Provision VMs on        Sync App of Apps
 templates          3 Proxmox hosts         from chart/
    │                      │                      │
    │               Configure Talos          Generate one
    │               machine configs          Application per
    │                      │                 addon in addons/
    │               Bootstrap cluster              │
    │                      │                 Auto-heal and
    │               Install ArgoCD           prune on drift
    │               via Helm                       │
    │                      │                       ▼
    └──────────────────────┴───── All 29 addons deployed ──────
```

### Adding a New Addon

1. Create `addons/<name>/Chart.yaml` with upstream Helm dependency
2. Create `addons/<name>/values.yaml` with overrides
3. Create `chart/templates/<name>.yaml` (ArgoCD Application)
4. Add toggle to `chart/values.yaml`
5. Push to `main` — ArgoCD deploys automatically

### Security Pipeline

Falco and Wazuh run as DaemonSets on every node, sharing a hostPath volume:

```
  Kernel syscalls
        │
        ▼ (eBPF probe)
  ┌──────────┐     /var/log/falco/events.json     ┌──────────────┐
  │  Falco   │ ──────────── hostPath ────────────> │ Wazuh Agent  │
  │ DaemonSet│     (JSON alerts on each node)      │  DaemonSet   │
  └──────────┘                                     └──────┬───────┘
                                                          │ 1514/tcp
                                                   ┌──────▼───────┐
                                                   │ Wazuh Manager│
                                                   │   (Worker)   │
                                                   └──────┬───────┘
                                                          │ cluster sync
                                                   ┌──────▼───────┐
                                                   │ Wazuh Manager│
                                                   │   (Master)   │
                                                   └──────┬───────┘
                                                          │
                                                   ┌──────▼───────┐
                                                   │   OpenSearch  │──> Wazuh Dashboard
                                                   │   (Indexer)   │    wazuh.homelab.home
                                                   └──────────────┘
```

## Secrets Management

Secrets are encrypted with [SOPS](https://github.com/getsops/sops) + AWS KMS:

```bash
# Encrypt
sops -e config/secrets/homelab.yaml > config/secrets/homelab.enc.yaml

# Decrypt
sops -d config/secrets/homelab.enc.yaml > config/secrets/homelab.yaml
```

ArgoCD decrypts at sync time via the `helm-secrets` plugin.
