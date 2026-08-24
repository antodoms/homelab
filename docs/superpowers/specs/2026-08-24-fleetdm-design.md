# FleetDM: Device Management for the Home Network

**Date:** 2026-08-24
**Status:** Approved

## Goal

Run [Fleet](https://fleetdm.com) in the cluster so devices on the home network
(laptops, desktops, servers) can be enrolled with the fleetd/osquery agent for
inventory, live queries, policies, and scripts. osquery visibility only for
now — MDM (APNs, enrollment profiles) is a later config-only addition, not
part of this design.

## Constraints that shaped the design

- Fleet requires **MySQL 8** (tested: 8.0.44 / 8.4.x / 9.5.0). It does not
  support Postgres, so CloudNativePG cannot serve it. MariaDB support is in
  progress upstream ([fleetdm/fleet#27400](https://github.com/fleetdm/fleet/issues/27400))
  but the FAQ still advises against MariaDB today, so `mariadb-operator` is
  out until that ships.
- Fleet requires **Redis** for live-query sessions and caching.
- The official Fleet chart (v7.0.16, appVersion v4.90.1 as of this writing)
  removed its bundled Bitnami MySQL/Redis subcharts — we bring our own.
- fleetd agents require TLS. The cluster's ingress TLS comes from the
  self-signed homelab CA (`ingress` ClusterIssuer), so enrollment packages
  must embed the CA cert.

## Approach

Single new addon following the wazuh pattern: `addons/fleet` wraps the
official Fleet chart (`https://fleetdm.github.io/fleet/charts`, chart `fleet`)
as a dependency and adds hand-rolled templates for MySQL, Redis, secrets, and
the HTTPRoute. One ArgoCD Application, gated by `fleet.enable` in the root
chart. Decisions made during brainstorming:

- **MySQL as a simple single-replica StatefulSet** (official `mysql:8.4`
  image) rather than an operator (MOCO / Oracle / Percona). One small DB does
  not justify new CRDs; Mayastor's 3-way replication covers node loss. If
  Fleet ships MariaDB support later, migrating to `mariadb-operator` is the
  CNPG-like end state.
- **Wrap the official chart** rather than hand-rolling the server Deployment —
  it handles DB migrations, probes, and env wiring; Renovate bumps versions.
  Chart releases occasionally lag server releases; the image tag can be
  overridden if needed.
- **TLS terminates at the gateway** like every other app; Fleet itself runs
  plain HTTP in-cluster (`fleet.tls.enabled=false`).

## Components

### 1. Root chart wiring

- `chart/templates/fleet.yaml` — ArgoCD Application modeled on `wazuh.yaml`:
  path `addons/fleet`, destination namespace `fleet`,
  `secrets://../../config/secrets/homelab.enc.yaml` valueFiles, hostname
  parameter `httproute.hostnames[0]=fleet.{{ .Values.ingressDomain }}`,
  automated sync with selfHeal/prune/retry, `CreateNamespace=true`.
  No privileged PSS labels (Fleet runs non-root) and no `ignoreDifferences`
  unless a concrete drift problem appears.
- `chart/values.yaml` — new block:

```yaml
fleet:
  enable: true
  createNamespace: true
```

### 2. `addons/fleet` chart

`Chart.yaml` dependency: `fleet` v7.0.16 from
`https://fleetdm.github.io/fleet/charts` (Renovate-managed thereafter).

Upstream chart values (under the `fleet:` key in `addons/fleet/values.yaml`):

```yaml
fleet:
  replicas: 1
  fleet:
    tls:
      enabled: false
  database:
    address: fleet-mysql:3306
    database: fleet
    username: fleet
    secretName: fleet-mysql        # our template renders this Secret
  cache:
    address: fleet-redis:6379
  # resources trimmed to homelab scale (~256Mi request / 1Gi limit)
```

Hand-rolled templates in `addons/fleet/templates/`:

- **mysql-statefulset.yaml + mysql-service.yaml** — single replica,
  `mysql:8.4`, 10Gi PVC on `mayastor-sc`, creates database `fleet` and user
  `fleet` via the image's `MYSQL_DATABASE`/`MYSQL_USER` env, passwords from
  the `fleet-mysql` Secret.
- **redis-deployment.yaml + redis-service.yaml** — single replica,
  `redis:7-alpine`, no auth, no persistence (loss = dropped live-query
  sessions only).
- **secrets.yaml** — renders the `fleet-mysql` Secret (root + fleet user
  passwords, key names matching the upstream chart's `passwordKey`
  expectation) and the Fleet server private key Secret, all sourced from
  SOPS-provided values.
- **httproute.yaml** — `homelab-gateway` https listener parentRef, hostname
  injected by the root chart, backend `fleet` service port 8080 (same shape
  as keep's httproute).

### 3. Secrets (`config/secrets/homelab.enc.yaml`)

New SOPS keys (added with `sops` — mind the helm-secrets gotcha: keys must be
encrypted in place, never committed as plaintext):

```yaml
fleet:
  mysqlRootPassword: <generated>
  mysqlPassword: <generated>          # fleet user
  serverPrivateKey: <32+ random chars> # FLEET_SERVER_PRIVATE_KEY — required
                                       # by newer Fleet features, cheap to set now
```

The exact upstream-chart mechanism for wiring `FLEET_SERVER_PRIVATE_KEY`
(dedicated value vs `extraEnvFrom`) is confirmed at implementation time
against chart v7.0.16's values.

### 4. Device enrollment (ops, post-deploy)

fleetd → `https://fleet.homelab.home` → AdGuard DNS → MetalLB LB IP →
Envoy Gateway (homelab CA TLS) → fleet service :8080.

Per device: export the homelab CA cert, then build an installer with

```sh
fleetctl package --type=pkg|msi|deb \
  --fleet-url=https://fleet.homelab.home \
  --enroll-secret=<from Fleet UI> \
  --fleet-certificate=homelab-ca.pem
```

Documented as a runbook step; devices must resolve `fleet.homelab.home` via
AdGuard (or a hosts entry).

**Known limitation:** internal-only exposure means roaming laptops stop
checking in when off the home network. Acceptable for the stated goal;
external exposure (real cert + tunnel/port-forward) would be its own design.

## Error handling

- First sync: Fleet pods crashloop until MySQL finishes initializing; ArgoCD
  selfHeal + retry converges without intervention.
- Upgrades: `autoApplySQLMigrations=true` runs migrations automatically.
- MySQL pod loss: StatefulSet reschedules and remounts the Mayastor volume
  (3-way replicated).
- Redis loss: in-flight live queries drop; no durable state affected.

## Verification

1. `helm dependency build addons/fleet` and `helm template` render cleanly.
2. ArgoCD app syncs healthy; MySQL, Redis, and Fleet pods all Ready.
3. Fleet UI reachable at `https://fleet.homelab.home` with homelab-CA TLS;
   initial admin setup completes.
4. One real device enrolls via a fleetd package built with the CA cert and
   appears in the Hosts list.

## Out of scope

- MDM (macOS APNs / Windows enrollment) — config-only addition later.
- SSO — Fleet free tier is SAML-only; the existing Zoho pattern is OIDC.
  Separate design if wanted.
- PodMonitor / Prometheus scraping of Fleet metrics.
- MySQL backups beyond Mayastor replication.
