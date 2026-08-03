variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "proxmox_endpoint" {
  description = "API Adress for Proxmox VE"
  type        = string
  default     = "https://192.168.0.10:8006/"
}

variable "ssh_public_key_path" {
  description = "Local path to public ssh key for VMs"
  type        = string
}

variable "vms" {
    description = "Virtual machines managed by lab"

    type = map(object({
        vm_id = number
        cpu_cores = number
        memory_mb = number
        ipv4_address = string
        tags = list(string)
    }))
}