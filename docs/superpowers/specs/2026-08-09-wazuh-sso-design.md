# Wazuh SSO: Zoho OIDC via Chart-Native OpenSearch Security

**Date:** 2026-08-09
**Status:** Approved
**Extends:** [2026-08-08-sso-zoho-oauth-design.md](2026-08-08-sso-zoho-oauth-design.md) (which deferred Wazuh)

## Goal

Zoho SSO for the Wazuh dashboard, reusing the existing Zoho OAuth app and the
single `config/secrets/homelab.enc.yaml` SOPS file. Admin emails get
`all_access`; any other authenticated Zoho account gets read-only (matching
the Grafana/ArgoCD access model). The local admin login stays as break-glass.

## Approach

Chart-native: the vendored `wazuh` chart (morgoved/wazuh-helm 1.0.22) ships
`dashboard.sso.oidc.*` values that render an `openid_auth_domain` into the
indexer's OpenSearch Security `config.yml` and enable the dashboard's
multi-auth (basic + OIDC) login page. No security-file overrides.

**Zoho quirk:** Zoho ID tokens carry no roles claim. Setting
`rolesKey: email` makes each user's email act as their backend role, so the
chart's built-in `roleMappings.allAccess.backendRoles: [<admin emails>]` knob
grants admin — the same email-driven RBAC trick as ArgoCD's `policy.csv`.

## Components

### 1. Zoho OAuth app (manual, one-time)
Add a third redirect URI to the existing app at api-console.zoho.com:
`https://wazuh.homelab.home/auth/openid/login`

### 2. Public `addons/wazuh/values.yaml` (non-sensitive)
```yaml
wazuh:
  dashboard:
    sso:
      oidc:
        enabled: true
        url: https://accounts.zoho.com/.well-known/openid-configuration
        baseRedirectUrl: https://wazuh.homelab.home
        scope: "openid email profile"
        existingSecret: wazuh-oidc-credentials
        config:
          subjectKey: email
          rolesKey: email
    basicAuth:
      enabled: true   # selector page + break-glass local admin (chart default)
    networkPolicy:
      extraEgresses:  # dashboard validates tokens against Zoho JWKS
        - to: [{ ipBlock: { cidr: 0.0.0.0/0 } }]
          ports: [{ port: 443, protocol: TCP }]
  indexer:
    networkPolicy:
      extraEgresses:  # indexer's openid_auth_domain fetches JWKS too
        - to: [{ ipBlock: { cidr: 0.0.0.0/0 } }]
          ports: [{ port: 443, protocol: TCP }]
    config:
      rolesMapping: |
        # Copy of the chart's built-in roles_mapping template (helpers keep
        # their tpl directives, so the SOPS allAccess.backendRoles knob still
        # flows in) with exactly two lines changed for the viewer tier:
        #   readall.users:     [] → ["*"]
        #   kibana_user.users: [] → ["*"]
        ...
```

**Viewer-tier mechanism (why the override):** `readall` and `kibana_user`
mapping keys are already rendered by the chart's built-in template, and
`extraRoleMappings` appends to the same YAML document — duplicate keys with
parser-dependent behavior. Overriding `indexer.config.rolesMapping` (a
`tpl`-rendered string value) with a modified copy is deterministic. The copy
must be re-diffed against the chart's helper on chart version bumps (note
added beside the renovate pin).

### 3. New template `addons/wazuh/templates/oidc-secret.yaml`
Renders Secret `wazuh-oidc-credentials` with keys
`OPENSEARCH_OIDC_CLIENT_ID` / `OPENSEARCH_OIDC_CLIENT_SECRET` from
`.Values.wazuh.dashboard.sso.oidc.clientId|clientSecret` — values that exist
only in the SOPS file.

### 4. `chart/templates/wazuh.yaml`
Add the encrypted values file to the Application, same as
kube-prometheus-stack:
```yaml
valueFiles:
  - secrets://../../config/secrets/homelab.enc.yaml
```

### 5. SOPS `config/secrets/homelab.enc.yaml` (already added by user)
```yaml
wazuh:
  dashboard:
    sso:
      oidc:
        clientId: ENC[...]
        clientSecret: ENC[...]
        roleMappings:
          allAccess:
            backendRoles: [ ENC[...] ]   # admin emails
```

## RBAC Summary

| Who | Wazuh |
|-----|-------|
| Emails in SOPS `allAccess.backendRoles` | all_access |
| Any other Zoho account | read-only (dashboards + read indices) |
| Local `admin` (internal user) | unchanged, break-glass via login form |

## Data Flow

Browser → wazuh.homelab.home (envoy) → dashboard login page → "Log in with
SSO" → Zoho → redirect to `/auth/openid/login` → dashboard/indexer validate
token against Zoho JWKS (needs egress 443) → security plugin maps
email-as-backend-role → roles.

## Error Handling / Rollback

- OIDC misconfig cannot lock anyone out: basic auth stays enabled, local
  admin unaffected.
- Security config changes are applied by the chart's indexer securityadmin
  job on sync; if the job fails, previous auth config stays active.
- Rollback = revert the commit; ArgoCD prunes the Secret and restores the
  previous security config.

## Verification

1. ArgoCD `wazuh` app Synced/Healthy; securityadmin job completed.
2. Login page shows both basic auth and SSO button.
3. Admin email via SSO → full access (can see Security plugin admin UI).
4. Non-admin Zoho account → read-only (dashboards visible, no write/admin).
5. Local `admin` login still works.

## Out of Scope

- SSO for Keep/OpenObserve (future, same pattern).
- Wazuh API/agent auth (unchanged; SSO covers the dashboard only).
- Tightening `config/.sops.yaml` path_regex (flagged separately).
