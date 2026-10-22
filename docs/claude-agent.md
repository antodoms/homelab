# Claude agent (in-cluster Remote Control)

`addons/claude-agent` runs Claude Code as a Remote Control server inside the
cluster so you can ask about the cluster from the Claude app (or claude.ai/code)
while away from home. Everything is outbound: no ingress, no VPN.

## What it can do

- `kubectl` with its own ServiceAccount: the built-in `view` role plus read on
  nodes, PVs, storage classes, CRDs, ArgoCD apps, cert-manager, Gateway API,
  OpenEBS, MetalLB, CNPG, Prometheus operator and VPA resources. No Secrets,
  no writes.
- Reads the GitOps repo (cloned into its home on start) and proposes fixes as
  repo changes. ArgoCD applies them after you merge.
- No talosctl, kubeconfig, or SOPS/AWS access. Node-level Talos work still
  happens from your own machine.

## One-time setup

Remote Control needs a full claude.ai login (API keys and `claude setup-token`
tokens are rejected) and a trusted working directory, both interactive. After
ArgoCD syncs the app:

```sh
kubectl -n claude-agent exec -it deploy/claude-agent -- claude-agent-setup
```

1. Follow the `claude auth login` prompt (claude.ai account, paste the code).
2. Claude starts in `~/homelab`: accept the trust prompt, optionally ask it to
   `kubectl get nodes`, then `/exit`.
3. It then runs `claude remote-control` once: answer `y` to the one-time
   "Enable Remote Control?" confirmation, wait for the session URL, and press
   Ctrl+C.
4. Within a minute the pod starts `claude remote-control --name homelab-cluster`.

If you set it up before the confirmation step existed and the phone shows no
session, the pod's server is stuck on that prompt. Accept it once and restart:

```sh
kubectl -n claude-agent exec -it deploy/claude-agent -- bash -c 'cd ~/homelab && claude remote-control --spawn session'
# answer y, wait for the session URL, Ctrl+C
kubectl -n claude-agent rollout restart deploy/claude-agent
```

The login and trust live on the `claude-agent-home` PVC, so restarts don't
need this again. Re-run the setup if the login expires or the PVC is lost.

## Using it

Open the Claude app → Code, pick the **homelab-cluster** session (or start a
new one on that environment) and ask away. Sessions start in auto mode
(`permissionMode` in values), so routine commands run without prompting;
read-only kubectl commands are also pre-approved in `~/.claude/settings.json`.
Set `permissionMode: default` to approve every other command yourself.

```sh
kubectl -n claude-agent logs deploy/claude-agent   # server status / session URL
```

## Widening access

Writes are deliberately off. To allow e.g. restarting deployments, add a
rule to `rbac.extraReadRules` in `addons/claude-agent/values.yaml` — or better,
a separate Role with the specific verbs — rather than binding `edit`/`admin`.

## Notes

- The NetworkPolicy (egress to DNS, 443, 6443 only) is only enforced with a
  policy-aware CNI; the default Talos flannel ignores it.
- Claude Code and kubectl are installed onto the PVC at first start; Claude
  Code then updates itself. Bump `kubectlVersion` with cluster upgrades.
