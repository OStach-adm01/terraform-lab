locals {
  vm_defaults = {
    node_name      = "pve"
    pool_id        = "terraform-lab"
    template_vm_id = 300
    datastore_id   = "local-lvm"
    bios           = "ovmf"
    machine        = "q35"
    scsi_hardware  = "virtio-scsi-single"
    cpu_type       = "host"

    efi_disk = {
      datastore_id      = "local-lvm"
      pre_enrolled_keys = true
    }

    network_bridge = "vmbr0"
    ipv4_gateway   = "192.168.0.1"
    dns_servers    = ["192.168.0.1"]
    dns_domain     = "stan.lab"
  }
  admin_ssh_public_key = trimspace(
    file(pathexpand(var.admin_ssh_public_key_path))
  )
  ansible_ssh_public_key = trimspace(
    file(pathexpand(var.ansible_ssh_public_key_path))
  )
}

module "proxmox_vm" {
  for_each = var.vms

  source = "./modules/proxmox-vm"

  vm = merge(
    local.vm_defaults,
    each.value,
    {
      name = replace(each.key, "_", "-")
      ssh_public_keys = concat(
        [local.admin_ssh_public_key],
        each.value.ansible_managed ? [local.ansible_ssh_public_key] : []
      )
    }
  )
}