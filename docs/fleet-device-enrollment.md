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
