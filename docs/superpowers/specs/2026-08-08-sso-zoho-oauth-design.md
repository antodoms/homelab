# SSO Design: Native OIDC with Zoho OAuth

**Date:** 2026-08-08
**Status:** Approved

## Goal

Single sign-on for Grafana and ArgoCD using one Zoho OAuth app. Each app handles its own OIDC flow natively — no gateway auth proxy needed. Role assignment (admin vs viewer) is driven by email and stored in SOPS secrets, never exposed in the public repo.

## Architecture

```
Browser
  │
  ├──▶ grafana.homelab.home ──▶ Grafana (Generic OAuth → Zoho)
  │                              role_attribute_path maps email → GrafanaAdmin / Viewer
  │
  └──▶ argocd.homelab.home  ──▶ ArgoCD (Dex → Zoho OIDC)
                                 policy.csv maps email → role:admin / role:readonly
```

One Zoho OAuth app, two redirect URIs registered on it. No separate auth proxy needed.

## Components

### 1. Zoho OAuth App (one-time manual step)

Register at [api-console.zoho.com](https://api-console.zoho.com). Free, no plan required.

- **Client type:** Server-based application
- **Scopes:** `openid`, `email`, `profile`
- **Redirect URIs (both on the same app):**
  - `https://grafana.homelab.home/login/generic_oauth`
  - `https://argocd.homelab.home/api/dex/callback`
- Output: `client_id`, `client_secret` → stored in SOPS secrets

### 2. Grafana (`addons/kube-prometheus-stack/values.yaml` + secrets)

Enable Generic OAuth in `grafana.ini`. Sensitive values (client ID, secret, admin email list) come from the SOPS-encrypted secrets file — nothing sensitive in the public values.yaml.

Public `values.yaml` sets the non-sensitive structure:

```yaml
grafana.ini:
  auth.generic_oauth:
    enabled: true
    name: Zoho
    allow_sign_up: true
    scopes: openid email profile
    auth_url: https://accounts.zoho.com/oauth/v2/auth
    token_url: https://accounts.zoho.com/oauth/v2/token
    api_url: https://accounts.zoho.com/oauth/v2/userinfo
    use_pkce: true
  auth:
    disable_login_form: true
```

SOPS secrets file provides the sensitive overrides:

```yaml
kube-prometheus-stack:
  grafana:
    grafana.ini:
      auth.generic_oauth:
        client_id: "<zoho_client_id>"
        client_secret: "<zoho_client_secret>"
        role_attribute_path: "contains(['anto@zetech.com.au'], email) && 'GrafanaAdmin' || 'Viewer'"
```

The `role_attribute_path` is a JMESPath expression evaluated against the Zoho userinfo response. The admin email list lives only in the SOPS secrets file.

### 3. ArgoCD (`addons/argocd/values.yaml` + secrets)

Re-enable Dex and configure a Zoho OIDC connector. Client credentials and admin email list come from SOPS.

Public `values.yaml`:

```yaml
dex:
  enabled: true

configs:
  cm:
    url: https://argocd.homelab.home
  secret:
    extra:
      dex.zoho.clientID: ""     # overridden by secrets
      dex.zoho.clientSecret: "" # overridden by secrets
```

SOPS secrets file provides:

```yaml
argo-cd:
  configs:
    cm:
      dex.config: |
        connectors:
        - type: oidc
          id: zoho
          name: Zoho
          config:
            issuer: https://accounts.zoho.com
            clientID: $dex.zoho.clientID
            clientSecret: $dex.zoho.clientSecret
            redirectURI: https://argocd.homelab.home/api/dex/callback
            scopes: [openid, email, profile]
    secret:
      extra:
        dex.zoho.clientID: "<zoho_client_id>"
        dex.zoho.clientSecret: "<zoho_client_secret>"
    rbac:
      policy.csv: |
        g, anto@zetech.com.au, role:admin
      policy.default: role:readonly
```

The `policy.csv` (which exposes admin emails) lives only in the SOPS secrets file.

## Secrets Structure

Add the following block to `config/secrets/homelab.yaml` before re-encrypting:

```yaml
sso:
  zoho_client_id: "1000.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  zoho_client_secret: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  admin_emails:
    - anto@zetech.com.au
```

The `admin_emails` list is the source of truth. During implementation, the `role_attribute_path` for Grafana and `policy.csv` for ArgoCD will be templated from this list.

## RBAC Summary

| Who | Grafana | ArgoCD |
|-----|---------|--------|
| `anto@zetech.com.au` | GrafanaAdmin (auto via JMESPath) | role:admin |
| Any other Zoho user | Viewer (auto via JMESPath) | role:readonly |
| Non-Zoho / unauthenticated | Blocked by Zoho OAuth | Blocked by Dex |

## New Files / Changes

| Path | Change |
|------|--------|
| `addons/kube-prometheus-stack/values.yaml` | Add `grafana.ini.auth.generic_oauth` non-sensitive config |
| `addons/argocd/values.yaml` | Enable Dex, add Zoho connector structure |
| `config/secrets/homelab.yaml` | Add `sso` block: client ID, secret, admin emails (SOPS) |

## What Was Dropped vs Original Design

| Original | Revised | Reason |
|----------|---------|--------|
| oauth2-proxy deployment | Removed | Not needed; each app handles its own OIDC |
| Envoy SecurityPolicy (ExtAuth) | Removed | Same reason |
| Grafana auth.proxy mode | Replaced with Generic OAuth | Enables automatic role assignment via `role_attribute_path`; no manual admin promotion needed |

## Out of Scope

- SSO for other services (Wazuh, Keep, OpenObserve) — can reuse the same Zoho app with additional redirect URIs later
- Zoho group-based RBAC — personal accounts don't have teams; email-based JMESPath is used instead
