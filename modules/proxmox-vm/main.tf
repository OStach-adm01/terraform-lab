resource "proxmox_virtual_environment_vm" "this" {
    name = var.vm.name
    description = "Managed by Terraform"
    tags = var.vm.tags

    node_name = var.vm.node_name
    vm_id = var.vm.vm_id
    pool_id = var.vm.pool_id
    started = true

    agent {
        enabled = true
    

    wait_for_ip {
        ipv4 = true
    }
}

stop_on_destroy = true

clone {
    vm_id = var.vm.template_vm_id
    node_name = var.vm.node_name
    datastore_id = var.vm.datastore_id
}

cpu {
    cores = var.vm.cpu_cores
}

memory {
    dedicated = var.vm.memory_dedicated
}

initialization {
    datastore_id = var.vm.datastore_id

    dns {
        servers = var.vm.dns_servers
        domain = var.vm.dns_domain
    }

    ip_config {
        ipv4 {
            address = var.vm.ipv4_address
            gateway = var.vm.ipv4_gateway
        }
    }

    user_account {
        username = var.vm.username
        keys = [trimspace(var.vm.ssh_public_key)]
    }
}

network_device {
    bridge = var.vm.network_bridge
}
}