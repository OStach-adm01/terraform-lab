resource "proxmox_virtual_environment_vm" "this" {
  name        = var.vm.name
  description = "Managed by Terraform"
  tags        = var.vm.tags

  node_name     = var.vm.node_name
  vm_id         = var.vm.vm_id
  pool_id       = var.vm.pool_id
  started       = true
  bios          = var.vm.bios
  machine       = var.vm.machine
  scsi_hardware = var.vm.scsi_hardware

  efi_disk {
    datastore_id      = var.vm.efi_disk.datastore_id
    pre_enrolled_keys = var.vm.efi_disk.pre_enrolled_keys
  }

  agent {
    enabled = true


    wait_for_ip {
      ipv4 = true
    }
  }

  stop_on_destroy = true

  clone {
    vm_id        = var.vm.template_vm_id
    node_name    = var.vm.node_name
    datastore_id = var.vm.datastore_id
  }

  cpu {
    cores = var.vm.cpu_cores
    type  = var.vm.cpu_type
  }

  memory {
    dedicated = var.vm.memory_mb
  }

  initialization {
    datastore_id = var.vm.datastore_id

    dns {
      servers = var.vm.dns_servers
      domain  = var.vm.dns_domain
    }

    ip_config {
      ipv4 {
        address = var.vm.ipv4_address
        gateway = var.vm.ipv4_gateway
      }
    }

    user_account {
      username = var.vm.username
      keys     = [trimspace(var.vm.ssh_public_key)]
    }
  }

  network_device {
    bridge = var.vm.network_bridge
  }
}