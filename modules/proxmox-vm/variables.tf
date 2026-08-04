variable "vm" {
  description = "Configuration of Proxmox VM"

  type = object({
    name           = string
    vm_id          = number
    node_name      = string
    pool_id        = string
    template_vm_id = number
    datastore_id   = string
    bios           = string
    machine        = string
    cpu_type       = string
    scsi_hardware  = string

    efi_disk = object({
      datastore_id      = string
      pre_enrolled_keys = bool
    })

    cpu_cores = number
    memory_mb = number

    network_bridge = string
    ipv4_address   = string
    ipv4_gateway   = string
    dns_servers    = list(string)
    dns_domain     = string

    ssh_public_key = string
    username       = optional(string, "devops")
    tags           = list(string)
  })
}