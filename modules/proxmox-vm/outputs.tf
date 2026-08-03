output "name" {
    value = proxmox_virtual_environment_vm.this.name
}

output "vm_id" {
    value = proxmox_virtual_environment_vm.this.vm_id
}

output "ipv4_address" {
    value = var.vm.ipv4_address
}