output "vm_ipv4_addresses" {
  description = "Static IPv4 addreses of lab vms"

  value = {
    for name, vm in module.proxmox_vm :
    name => vm.ipv4_address
  }
}