# FleetDM Addon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy Fleet (fleetdm) to the homelab cluster as a GitOps-managed addon so home-network devices can be enrolled with fleetd/osquery.

**Architecture:** One new ArgoCD Application (`fleet`) rendered by the root app-of-apps chart, pointing at a new `addons/fleet` Helm chart that wraps the official Fleet chart v7.0.16 as a vendored dependency. The chart's bundled MySQL StatefulSet subchart and Valkey subchart provide the datastores; TLS terminates at the existing Envoy Gateway with the homelab CA.

**Tech Stack:** Helm 3, ArgoCD + helm-secrets/SOPS, Gateway API (Envoy Gateway), OpenEBS Mayastor, Fleet chart v7.0.16 (appVersion v4.90.1).

**Spec:** `docs/superpowers/specs/2026-08-24-fleetdm-design.md`

## Global Constraints

- GitOps only: cluster changes land by committing to `main`; never `kubectl apply/patch/edit` cluster state by hand.
- Fleet chart pinned at `v7.0.16` from `https://fleetdm.github.io/fleet/charts`, vendored as `addons/fleet/charts/fleet-v7.0.16.tgz` (committed, like `addons/wazuh/charts/wazuh-1.0.22.tgz`) because the ArgoCD repo-server does not run `helm dependency build`.
- Secrets live only in `config/secrets/homelab.enc.yaml` (SOPS). The plaintext working copy `config/secrets/homelab.yaml` is gitignored and MUST never be committed or echoed into logs.
- Release/app name is exactly `fleet` — subchart resource names (`fleet-mysql`, `fleet-valkey`, `fleet-service`) depend on it.
- Storage class `mayastor-sc`; ingress hostname `fleet.<ingressDomain>` where `ingressDomain=homelab.home` is injected by bootstrap into the root chart.
- Kubeconfig for verification: `proxmox-talos/outputs/homelab/kubeconfig` (from repo root).
- All commits end with the `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` trailer.

---

### Task 1: `addons/fleet` chart

**Files:**
- Create: `addons/fleet/Chart.yaml`
- Create: `addons/fleet/values.yaml`
- Create: `addons/fleet/templates/secret-server-private-key.yaml`
- Create: `addons/fleet/templates/httproute.yaml`
- Generated (committed): `addons/fleet/Chart.lock`, `addons/fleet/charts/fleet-v7.0.16.tgz`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: a Helm chart at `addons/fleet` whose values scope is: `fleet.*` = upstream chart values (incl. `fleet.mysql.auth.rootPassword`, `fleet.mysql.auth.password` expected from SOPS at deploy time), `fleetSecrets.serverPrivateKey` = string consumed by our Secret template, `httproute.hostnames` = list set by the root chart parameter `httproute.hostnames[0]`. Task 3's Application manifest depends on exactly these paths.

- [ ] **Step 1: Write `addons/fleet/Chart.yaml`**

```yaml
apiVersion: v2
name: fleet
description: A Helm chart for Fleet (fleetdm) device management

type: application

# The chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
version: 0.1.0

# Version number of the application being deployed.
appVersion: "v4.90.1"

dependencies:
  - name: fleet
    version: v7.0.16
    repository: https://fleetdm.github.io/fleet/charts
```

- [ ] **Step 2: Vendor the dependency**

Run (from repo root):
```bash
helm dependency build addons/fleet
ls addons/fleet/charts/
```
Expected: `Chart.lock` created and `addons/fleet/charts/fleet-v7.0.16.tgz` listed. If `helm` complains the repo is unknown, run `helm repo add fleetdm https://fleetdm.github.io/fleet/charts && helm repo update fleetdm` and retry.

- [ ] **Step 3: Write `addons/fleet/values.yaml`**

```yaml
# Fleet (fleetdm) — osquery-based device management for the home network.
# Everything under `fleet:` is the upstream chart's values scope
# (dependency name "fleet"). MySQL auth and the server private key are NOT
# set here — they merge in from SOPS via the Application's
# secrets://../../config/secrets/homelab.enc.yaml valueFiles
# (fleet.mysql.auth.* and fleetSecrets.serverPrivateKey).
fleet:
  replicas: 1
  resources:
    limits:
      cpu: 1
      # the chart default of 4Gi is only needed when vulnerability scans run
      # in the main pod; vulnProcessing.dedicated moves them out
      memory: 1Gi
    requests:
      cpu: 0.1
      memory: 256Mi
  # CVE processing runs as its own hourly CronJob with burst resources so the
  # main server pod stays small
  vulnProcessing:
    dedicated: true
  fleet:
    tls:
      enabled: false # TLS terminates at the envoy gateway (homelab CA)
    # With mysql.enabled=true the chart drops its Helm hooks from the
    # fleet-migration Job and the Job self-deletes via TTL; without these
    # annotations ArgoCD selfHeal would recreate it in a loop forever.
    migrationJobAnnotations:
      argocd.argoproj.io/hook: Sync
      argocd.argoproj.io/hook-delete-policy: HookSucceeded
  database:
    address: fleet-mysql:3306
    database: fleet
    username: fleet
    secretName: fleet-mysql # rendered by the mysql subchart
  cache:
    address: fleet-valkey:6379
  # legacy condition key — enables the valkey subchart (no auth, no
  # persistence: cache-only role, loss just drops live-query sessions)
  redis:
    enabled: true
  mysql:
    enabled: true
    # auth.rootPassword / auth.password MUST come from SOPS: the subchart's
    # lookup+randAlphaNum fallback re-randomizes passwords on every ArgoCD
    # render (repo-server lookup is always empty)
    primary:
      persistence:
        enabled: true
        size: 10Gi
        storageClass: mayastor-sc
  envsFrom:
    - name: FLEET_SERVER_PRIVATE_KEY
      valueFrom:
        secretKeyRef:
          name: fleet-server-private-key
          key: private-key

# Gateway API HTTPRoute (our template)
httproute:
  enabled: true
  annotations: {}
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: homelab-gateway
      namespace: envoy-gateway-system
      sectionName: https
  # [0] is overridden by the Application parameter httproute.hostnames[0]
  hostnames:
    - fleet.homelab.home

# SOPS-provided at deploy time; empty default keeps local renders working
fleetSecrets:
  serverPrivateKey: ""
```

- [ ] **Step 4: Write `addons/fleet/templates/secret-server-private-key.yaml`**

```yaml
{{- if .Values.fleetSecrets.serverPrivateKey -}}
apiVersion: v1
kind: Secret
metadata:
  name: fleet-server-private-key
  labels:
    app.kubernetes.io/name: fleet
    app.kubernetes.io/instance: {{ .Release.Name }}
type: Opaque
stringData:
  private-key: {{ .Values.fleetSecrets.serverPrivateKey | quote }}
{{- end }}
```

- [ ] **Step 5: Write `addons/fleet/templates/httproute.yaml`**

```yaml
{{- if .Values.httproute.enabled -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .Release.Name }}
  labels:
    app.kubernetes.io/name: fleet
    app.kubernetes.io/instance: {{ .Release.Name }}
  {{- with .Values.httproute.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with .Values.httproute.parentRefs }}
  parentRefs:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with .Values.httproute.hostnames }}
  hostnames:
    {{- toYaml . | nindent 2 }}
  {{- end }}
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - group: ""
      kind: Service
      # upstream helper "fleet.servicename" = <fullname>-service; with
      # release name "fleet" that is "fleet-service"
      name: {{ .Release.Name }}-service
      port: 8080
      weight: 1
{{- end }}
```

- [ ] **Step 6: Render test**

Run (from repo root):
```bash
helm template fleet addons/fleet \
  --set fleet.mysql.auth.rootPassword=testroot \
  --set fleet.mysql.auth.password=testpass \
  --set fleetSecrets.serverPrivateKey=testkey0123456789 \
  > /tmp/fleet-render.yaml && echo RENDER_OK
grep -c "kind: Deployment" /tmp/fleet-render.yaml
grep "name: fleet-mysql" /tmp/fleet-render.yaml | sort -u
grep "fleet-valkey" /tmp/fleet-render.yaml | head -3
grep -A2 "FLEET_MYSQL_ADDRESS" /tmp/fleet-render.yaml
grep -B2 -A6 "kind: HTTPRoute" /tmp/fleet-render.yaml | head -20
grep "argocd.argoproj.io/hook" /tmp/fleet-render.yaml
grep -A3 "name: FLEET_SERVER_PRIVATE_KEY" /tmp/fleet-render.yaml | head -5
grep "mysql-password: " /tmp/fleet-render.yaml
grep "storageClassName" /tmp/fleet-render.yaml
```
Expected:
- `RENDER_OK`; Deployment count ≥ 2 (fleet server + valkey).
- `name: fleet-mysql` appears (Service/StatefulSet/Secret from the subchart).
- `fleet-valkey` resources present.
- `FLEET_MYSQL_ADDRESS` value is `fleet-mysql:3306`.
- HTTPRoute has hostname `fleet.homelab.home` and backend `fleet-service` port 8080.
- Both `argocd.argoproj.io/hook: Sync` and `argocd.argoproj.io/hook-delete-policy: HookSucceeded` appear (migration Job).
- `FLEET_SERVER_PRIVATE_KEY` env uses `secretKeyRef` name `fleet-server-private-key`.
- `mysql-password: "testpass"` (deterministic — run the template command twice and diff to confirm no `randAlphaNum` churn).
- `storageClassName: "mayastor-sc"`.

- [ ] **Step 7: Render test without secrets (local-lint path)**

Run:
```bash
helm template fleet addons/fleet > /tmp/fleet-render-nosecrets.yaml && echo RENDER_OK
grep -c "fleet-server-private-key" /tmp/fleet-render-nosecrets.yaml || true
```
Expected: `RENDER_OK`; the Secret `fleet-server-private-key` is absent (guarded by the `if`), but the Deployment still references it via envsFrom (acceptable — real deploys always have the SOPS value; this render exists only so CI/lint without secrets doesn't break).

- [ ] **Step 8: Commit**

```bash
git add addons/fleet
git commit -m "feat(fleet): add fleet addon chart wrapping official chart v7.0.16

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: SOPS secrets

**Files:**
- Modify: `config/secrets/homelab.enc.yaml` (via the plaintext working copy + `make encrypt`; plaintext is gitignored and never committed)

**Interfaces:**
- Consumes: value paths defined in Task 1 (`fleet.mysql.auth.rootPassword`, `fleet.mysql.auth.password`, `fleetSecrets.serverPrivateKey`).
- Produces: those keys present and SOPS-encrypted in `config/secrets/homelab.enc.yaml`, which Task 3's Application mounts via `secrets://`.

- [ ] **Step 1: Refresh the plaintext working copy from the encrypted source of truth**

Run:
```bash
cd config && make decrypt && cd ..
```
Expected: exits 0; `config/secrets/homelab.yaml` regenerated. (If sops key material is unavailable this fails loudly — stop and report, do not proceed.)

- [ ] **Step 2: Generate secret values and append the new keys**

Run:
```bash
MYSQL_ROOT_PW=$(openssl rand -hex 16)
MYSQL_PW=$(openssl rand -hex 16)
FLEET_KEY=$(openssl rand -base64 32)
cat >> config/secrets/homelab.yaml <<EOF

# Fleet (fleetdm) — merges into addons/fleet values via secrets:// valueFiles
fleet:
  mysql:
    auth:
      rootPassword: "${MYSQL_ROOT_PW}"
      password: "${MYSQL_PW}"

fleetSecrets:
  serverPrivateKey: "${FLEET_KEY}"
EOF
```
Expected: no output. Do NOT print the values. Note: the shared enc file is mounted by other apps (wazuh, argo-cd); the new top-level keys arrive there as unused values, which is harmless and matches existing cross-app keys.

- [ ] **Step 3: Verify plaintext YAML is valid and keys are readable**

Run:
```bash
python3 -c "
import yaml
d = yaml.safe_load(open('config/secrets/homelab.yaml'))
assert d['fleet']['mysql']['auth']['rootPassword'], 'rootPassword missing'
assert d['fleet']['mysql']['auth']['password'], 'password missing'
assert len(d['fleetSecrets']['serverPrivateKey']) >= 32, 'private key too short'
print('PLAINTEXT_OK')
"
```
Expected: `PLAINTEXT_OK`.

- [ ] **Step 4: Encrypt**

Run:
```bash
cd config && make encrypt && cd ..
grep -c "ENC\[" config/secrets/homelab.enc.yaml
grep -n "rootPassword" config/secrets/homelab.enc.yaml | head -2
```
Expected: large `ENC[` count; the `rootPassword` line's value starts with `ENC[AES256_GCM,` (encrypted, not plaintext). The whole-file diff churn (every value re-encrypted with fresh MACs) is normal for this repo's `make encrypt` workflow.

- [ ] **Step 5: Round-trip check (guards helm-secrets silent-ciphertext passthrough)**

Run:
```bash
sops --decrypt config/secrets/homelab.enc.yaml | python3 -c "
import sys, yaml
d = yaml.safe_load(sys.stdin)
p = yaml.safe_load(open('config/secrets/homelab.yaml'))
assert d['fleet'] == p['fleet'] and d['fleetSecrets'] == p['fleetSecrets']
print('ROUNDTRIP_OK')
"
```
Expected: `ROUNDTRIP_OK`.

- [ ] **Step 6: Commit (enc file ONLY)**

```bash
git status --short config/secrets/   # MUST show only homelab.enc.yaml
git add config/secrets/homelab.enc.yaml
git commit -m "feat(fleet): add fleet mysql auth and server private key to SOPS secrets

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```
Expected: `git status` confirms `homelab.yaml` is untracked/ignored, never staged.

---

### Task 3: Root chart wiring

**Files:**
- Create: `chart/templates/fleet.yaml`
- Modify: `chart/values.yaml` (append a `fleet:` block after the `keep:` block, around line 124)

**Interfaces:**
- Consumes: `addons/fleet` chart (Task 1) and SOPS keys (Task 2).
- Produces: ArgoCD Application `fleet` in namespace `argocd`, release name `fleet`, destination namespace `fleet` — the names Task 4's verification commands use.

- [ ] **Step 1: Write `chart/templates/fleet.yaml`**

Modeled on `chart/templates/wazuh.yaml`, minus the privileged PSS namespace labels (Fleet, MySQL, and Valkey all run unprivileged) and with a deeper retry (first sync's migration hook fails until MySQL is up):

```yaml
{{- if and (.Values.fleet) (.Values.fleet.enable) -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fleet
  namespace: {{ .Values.argoNamespace | default "argocd" }}
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: {{ .Values.argoProject | default "default" }}
  source:
    repoURL: {{ .Values.repoUrl }}
    path: addons/fleet
    targetRevision: {{ .Values.targetRevision }}
    helm:
      valueFiles:
        # SOPS-encrypted secrets (fleet mysql auth, server private key)
        # decrypted at render time by helm-secrets on the repo-server —
        # same single-source relative-path pattern as argocd.yaml/wazuh.yaml.
        - secrets://../../config/secrets/homelab.enc.yaml
      parameters:
      - name: httproute.hostnames[0]
        value: fleet.{{ .Values.ingressDomain }}
  destination:
    server: {{ .Values.destinationServer | default "https://kubernetes.default.svc" }}
    namespace: fleet
  ignoreDifferences:
    - group: "*"
      kind: "*"
      jsonPointers:
        - /metadata/annotations
        - /metadata/labels
  syncPolicy:
    syncOptions:
    - RespectIgnoreDifferences=true
    - CreateNamespace={{ .Values.fleet.createNamespace }}
    - ServerSideApply=false
    automated:
      selfHeal: true
      prune: true
    retry:
      # deeper than the repo's usual limit:1 — the migration Sync hook fails
      # until the bundled mysql finishes its first init (~60-90s)
      limit: 5
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 2m
{{- end -}}
```

- [ ] **Step 2: Add the root values block**

In `chart/values.yaml`, immediately after the `keep:` block (`keep.enable/createNamespace`, ~line 124), insert:

```yaml

# Fleet (fleetdm) - osquery device management for home network devices
fleet:
  enable: true
  createNamespace: true
```

- [ ] **Step 3: Render test of the root chart**

Run (from repo root):
```bash
helm template homelab chart/ --set ingressDomain=homelab.home > /tmp/root-render.yaml && echo RENDER_OK
grep -B2 -A8 "path: addons/fleet" /tmp/root-render.yaml
grep -A1 "httproute.hostnames\[0\]" /tmp/root-render.yaml
```
Expected: `RENDER_OK`; an Application named `fleet` with `path: addons/fleet` and parameter value `fleet.homelab.home`. Also confirm the rest of the root chart still renders: `grep -c "kind: Application" /tmp/root-render.yaml` returns 21 (20 before this change).

- [ ] **Step 4: Commit**

```bash
git add chart/templates/fleet.yaml chart/values.yaml
git commit -m "feat(fleet): register fleet ArgoCD application in root chart

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Deploy, verify, and enrollment runbook

**Files:**
- Create: `docs/fleet-device-enrollment.md`

**Interfaces:**
- Consumes: Application `fleet` (Task 3), SOPS keys (Task 2).
- Produces: running Fleet at `https://fleet.homelab.home`; runbook for enrolling devices.

- [ ] **Step 1: Push to main (this is the deploy)**

```bash
git push origin main
```

- [ ] **Step 2: Watch the Application converge**

Run (from repo root; allow up to ~10 minutes — image pulls, mysql init, migration retries):
```bash
export KUBECONFIG=proxmox-talos/outputs/homelab/kubeconfig
kubectl -n argocd get application fleet
# repeat / watch until:
kubectl -n argocd get application fleet -o jsonpath='{.status.sync.status} {.status.health.status}{"\n"}'
```
Expected: eventually `Synced Healthy`. Transient `Degraded`/sync retries during the first ~5 minutes are expected (migration hook waits on mysql). If it stays failed after retries exhaust, read `kubectl -n argocd get application fleet -o jsonpath='{.status.operationState.message}'` and debug — do NOT kubectl-patch resources; fix via git.

- [ ] **Step 3: Verify workloads**

```bash
kubectl -n fleet get pods,pvc
```
Expected: `fleet-<hash>` Deployment pod 1/1 Running, `fleet-mysql-0` 1/1 Running, `fleet-valkey-<hash>` 1/1 Running; PVC `data-fleet-mysql-0` Bound (10Gi, mayastor-sc). No `fleet-migration` pod lingering (hook deleted on success).

- [ ] **Step 4: Verify the rendered secret matches SOPS (ciphertext-passthrough guard)**

```bash
test "$(kubectl -n fleet get secret fleet-mysql -o jsonpath='{.data.mysql-password}' | base64 -d)" \
  = "$(sops --decrypt config/secrets/homelab.enc.yaml | python3 -c 'import sys,yaml; print(yaml.safe_load(sys.stdin)["fleet"]["mysql"]["auth"]["password"], end="")')" \
  && echo SECRET_MATCH
```
Expected: `SECRET_MATCH`. If the live value looks like `ENC[AES256_GCM,...]`, helm-secrets silently passed ciphertext through — check the repo-server helm-secrets setup before anything else.

- [ ] **Step 5: Verify the route end-to-end**

```bash
GW_IP=$(kubectl -n envoy-gateway-system get svc -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].ip}')
echo "$GW_IP"
curl -sk --resolve fleet.homelab.home:443:"$GW_IP" https://fleet.homelab.home/setup -o /dev/null -w '%{http_code}\n'
```
Expected: a 10.30.0.50-100 address; HTTP `200`. Then from a LAN machine confirm DNS: `nslookup fleet.homelab.home` should return the same IP (AdGuard rewrites are runtime config — if it does not resolve, add a rewrite for `fleet.homelab.home` → `$GW_IP` in the AdGuard admin UI, or a wildcard `*.homelab.home` if not already present).

- [ ] **Step 6: Write `docs/fleet-device-enrollment.md`**

```markdown
# Enrolling home-network devices in Fleet

Fleet runs at <https://fleet.homelab.home> (osquery visibility; no MDM).
TLS is issued by the homelab CA, so every device needs the CA cert baked
into its fleetd installer.

## One-time: admin setup

Open <https://fleet.homelab.home> and complete the initial admin account
setup. Then copy the enroll secret from **Hosts → Manage enroll secret**.

## Per release: export the homelab CA cert

```sh
export KUBECONFIG=proxmox-talos/outputs/homelab/kubeconfig
kubectl -n cert-manager get secret ingress-tls \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > homelab-ca.pem
```

(The `ingress` ClusterIssuer is a self-signed CA; `tls.crt` IS the CA cert.
It rotates every 180 days — regenerate installers after rotation.)

## Build fleetd installers

Install fleetctl on your workstation (`brew install fleetctl`), then per
platform:

```sh
# macOS (--type=pkg); for Windows use --type=msi, Debian/Ubuntu --type=deb,
# Fedora/RHEL --type=rpm — all other flags identical
fleetctl package --type=pkg \
  --fleet-url=https://fleet.homelab.home \
  --enroll-secret=<enroll secret> \
  --fleet-certificate=homelab-ca.pem
```

Install the package on each device. It appears under **Hosts** within a
minute or two.

## Requirements on the device

- Must resolve `fleet.homelab.home` via AdGuard (home LAN DNS) — roaming
  devices stop checking in while off-network and resume when back.
```

- [ ] **Step 7: Enroll one device and confirm**

Build a package for your workstation's platform per the runbook, install it, and confirm the host appears in the Fleet UI **Hosts** list within ~2 minutes.
Expected: 1 host online.

- [ ] **Step 8: Commit and push the runbook**

```bash
git add docs/fleet-device-enrollment.md
git commit -m "docs(fleet): device enrollment runbook

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push origin main
```
