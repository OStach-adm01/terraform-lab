terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111.1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.0.10:8006/"
  insecure = true

  api_token = var.proxmox_api_token
}
