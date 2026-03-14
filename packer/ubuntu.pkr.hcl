source "proxmox" "ubuntu2204" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_nodename
  insecure_skip_tls_verify = true

  iso_file    = var.iso_file_path
  unmount_iso = true

  scsi_controller = "virtio-scsi-pci"
  network_adapters {
    bridge = var.proxmox_bridge
    model  = "virtio"
  }

  disks {
    type              = "scsi"
    storage_pool      = var.proxmox_storage
    storage_pool_type = var.proxmox_storage_type
    format            = "raw"
    disk_size         = "1500M"
    cache_mode        = "writethrough"
  }

  memory       = 2048
  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "15m"
  qemu_agent   = true

  template_name        = "ubuntu2204-cloud-init-template"
  template_description = "Ubuntu 22.04 cloud-init, built on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"

  boot_wait = "25s"
  boot_command = [
    "<enter><enter><f6><esc><wait>",
    "<bs><bs><bs><bs>",
    "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
    "--- <enter>"
  ]
}

build {
  name    = "release"
  sources = ["source.proxmox.ubuntu2204"]

  provisioner "shell" {
    inline = [
      "curl -L ${local.ubuntu_image} -o /tmp/ubuntu.raw.xz",
      "xz -d -c /tmp/ubuntu.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}
