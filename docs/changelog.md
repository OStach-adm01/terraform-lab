# Changelog

## 2026-08-04

### Added

- Created a reusable `proxmox-vm` Terraform module using a VM object interface.
- Added the `ansible-controller` definition to the versioned lab VM map.

### Infrastructure

- Provisioned `ansible-controller` (VMID 310) from the Ubuntu 24.04 template.
- Configured UEFI, q35, `virtio-scsi-single`, static IP `192.168.0.220/24`, QEMU guest agent, SSH key access, and passwordless sudo.
- Verified SSH connectivity, DNS resolution, HTTPS access, and Terraform state without drift.
