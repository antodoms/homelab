# Temporary import blocks - remove after successful apply

import {
  to = kubernetes_namespace_v1.media-center-operator
  id = "media-server-operator"
}

import {
  to = kubernetes_secret_v1.prowlarr_secrets[0]
  id = "media-server-operator/prowlarr-secrets"
}

import {
  to = kubernetes_secret_v1.mediafusion_secrets[0]
  id = "media-server-operator/mediafusion-secrets"
}

import {
  to = kubernetes_secret_v1.openclaw_api_keys[0]
  id = "openclaw-operator-system/openclaw-api-keys"
}

import {
  to = kubernetes_namespace_v1.openclaw_operator_system[0]
  id = "openclaw-operator-system"
}


import {
  to = module.compute_master["hp-gpu"].proxmox_vm_qemu.talos["0"]
  id = "hp-gpu/qemu/200"
}

import {
  to = module.compute_master["hp-z-server-a"].proxmox_vm_qemu.talos["0"]
  id = "hp-z-server-a/qemu/201"
}

import {
  to = module.compute_master["hp-z-server-b"].proxmox_vm_qemu.talos["0"]
  id = "hp-z-server-b/qemu/202"
}

import {
  to = module.compute_worker["hp-gpu"].proxmox_vm_qemu.talos["0"]
  id = "hp-gpu/qemu/300"
}

import {
  to = module.compute_worker["hp-gpu"].proxmox_vm_qemu.talos["1"]
  id = "hp-gpu/qemu/301"
}

import {
  to = module.compute_worker["hp-z-server-a"].proxmox_vm_qemu.talos["0"]
  id = "hp-z-server-a/qemu/302"
}

import {
  to = module.compute_worker["hp-z-server-b"].proxmox_vm_qemu.talos["0"]
  id = "hp-z-server-b/qemu/303"
}
