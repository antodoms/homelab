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
  replaced its old Bitnami MySQL/Redis subcharts with its own bundled
  **minimal MySQL StatefulSet subchart** and a **Valkey** (Redis-compatible)
  subchart, both off by default (`mysql.enabled` / `redis.enabled`).
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
  CNPG-like end state. The chart's bundled `mysql` subchart is exactly this
  StatefulSet, so we enable it instead of hand-rolling one.
- **Wrap the official chart** rather than hand-rolling the server Deployment —
  it handles DB migrations, probes, and env wiring; Renovate bumps versions.
  Chart releases occasionally lag server releases; the image tag can be
  overridden if needed.
- **Valkey subchart for the cache** (`redis.enabled=true` enables it; the
  condition key is legacy-named). Redis-protocol compatible, no persistence
  by default — matches the "cache only" role.
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

Upstream chart values (under the `fleet:` key in `addons/fleet/values.yaml`;
the release name is `fleet`, so subchart resources come out as `fleet-mysql`
and `fleet-valkey`, and the server Service is `fleet-service`):

```yaml
fleet:
  replicas: 1
  resources:
    limits: { cpu: 1, memory: 1Gi }      # the default 4Gi is only needed
                                         # when vuln scans run in-pod
  vulnProcessing:
    dedicated: true                      # CVE scans run in their own hourly
                                         # CronJob (4Gi burst) instead of the
                                         # main pod
  fleet:
    tls:
      enabled: false
    migrationJobAnnotations:
      argocd.argoproj.io/hook: Sync
      argocd.argoproj.io/hook-delete-policy: HookSucceeded
  database:
    address: fleet-mysql:3306
    secretName: fleet-mysql              # rendered by the mysql subchart
  cache:
    address: fleet-valkey:6379
  redis:
    enabled: true                        # legacy condition key → valkey subchart
  mysql:
    enabled: true
    primary:
      persistence: { size: 10Gi, storageClass: mayastor-sc }
  envsFrom:
    - name: FLEET_SERVER_PRIVATE_KEY
      valueFrom:
        secretKeyRef: { name: fleet-server-private-key, key: private-key }
```

Two chart-behavior gotchas the values above encode:

- **Migration job**: with `mysql.enabled=true` the chart drops its Helm
  hooks from the `fleet-migration` Job, and the Job self-deletes via TTL —
  under ArgoCD selfHeal it would be recreated in a loop forever. The
  `migrationJobAnnotations` turn it into an ArgoCD Sync hook that is deleted
  after success and never tracked as live state.
- **Deterministic passwords**: the mysql subchart's Secret falls back to
  `lookup` + `randAlphaNum` when `auth.*` passwords are unset. ArgoCD's
  repo-server renders with `lookup` empty, so unset passwords would be
  re-randomized on every sync. `mysql.auth.rootPassword/password` MUST be
  set explicitly (via SOPS).

Hand-rolled templates in `addons/fleet/templates/` (only two left):

- **secret-server-private-key.yaml** — Secret `fleet-server-private-key`
  (key `private-key`) from the SOPS-provided `fleetSecrets.serverPrivateKey`,
  consumed via the chart's `envsFrom`.
- **httproute.yaml** — `homelab-gateway` https listener parentRef, hostname
  injected by the root chart, backend `fleet-service` port 8080 (same shape
  as keep's httproute).

### 3. Secrets (`config/secrets/homelab.enc.yaml`)

New SOPS keys (added to the plaintext working copy, then `make encrypt` —
never commit the plaintext file; it is gitignored). Top-level keys mirror the
addon chart's values scope, so the mysql passwords merge straight into the
subchart:

```yaml
fleet:
  mysql:
    auth:
      rootPassword: <generated>
      password: <generated>            # fleet user

fleetSecrets:
  serverPrivateKey: <openssl rand -base64 32>  # FLEET_SERVER_PRIVATE_KEY —
                                               # required by newer Fleet
                                               # features, cheap to set now
```

The private key reaches the server as an env var via the chart's `envsFrom`
+ our `fleet-server-private-key` Secret (kept out of the Deployment manifest,
unlike the chart's plaintext `environments` map). The extra top-level keys
flow into every app that mounts the shared enc file (wazuh, argo-cd) as
unused values — harmless, same as the existing cross-app keys.

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

- First sync: the migration Sync-hook Job fails until the bundled MySQL
  finishes initializing, and Fleet pods crashloop until migrations complete.
  The Application sets a deeper retry (`limit: 5`) than the repo's usual 1 so
  the first install converges without a manual sync.
- Upgrades: `autoApplySQLMigrations=true` runs migrations automatically.
- MySQL pod loss: StatefulSet reschedules and remounts the Mayastor volume
  (3-way replicated).
- Valkey loss: in-flight live queries drop; no durable state affected.

## Verification

1. `helm dependency build addons/fleet` and `helm template` render cleanly.
2. ArgoCD app syncs healthy; MySQL, Valkey, and Fleet pods all Ready.
3. The live `fleet-mysql` Secret matches the SOPS plaintext (guards the
   helm-secrets silent-ciphertext-passthrough failure mode).
4. Fleet UI reachable at `https://fleet.homelab.home` with homelab-CA TLS;
   initial admin setup completes.
5. One real device enrolls via a fleetd package built with the CA cert
   (`ingress-tls` Secret in the `cert-manager` namespace) and appears in
   the Hosts list.

## Out of scope

- MDM (macOS APNs / Windows enrollment) — config-only addition later.
- SSO — Fleet free tier is SAML-only; the existing Zoho pattern is OIDC.
  Separate design if wanted.
- PodMonitor / Prometheus scraping of Fleet metrics.
- MySQL backups beyond Mayastor replication.
