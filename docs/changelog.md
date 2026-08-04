# Changelog

## 2026-08-04

### Added

- Created a reusable `proxmox-vm` Terraform module using a VM object interface.
- Added the `ansible-controller` definition to the versioned lab VM map.
- Added separate administrator and Ansible controller SSH keys for Ansible-managed VMs.
- Added the initial Ansible project structure with configuration, a local inventory, and an inspection playbook.
- Added definitions for one future Kubernetes control-plane VM and two worker VMs.

### Infrastructure

- Provisioned `ansible-controller` (VMID 310) from the Ubuntu 24.04 template.
- Configured UEFI, q35, `virtio-scsi-single`, static IP `192.168.0.220/24`, QEMU guest agent, SSH key access, and passwordless sudo.
- Verified SSH connectivity, DNS resolution, HTTPS access, and Terraform state without drift.
- Verified the local Ansible configuration and inspection playbook on `ansible-controller`.
- Created a dedicated Ansible controller SSH key pair; its private key remains outside the repository.
- Provisioned `k8s-cp-01` (VMID 311) at `192.168.0.221/24` with 2 vCPUs and 2 GB RAM.
- Provisioned `k8s-worker-01` (VMID 312) at `192.168.0.222/24` with 1 vCPU and 2 GB RAM.
- Provisioned `k8s-worker-02` (VMID 313) at `192.168.0.223/24` with 1 vCPU and 2 GB RAM.
- Confirmed that all four VM resources and their planned static IPv4 addresses are present in Terraform state.

### Documentation

- Clarified the boundary between Terraform provisioning, Ansible operating-system configuration, and Kubernetes cluster bootstrap in the roadmap.
- Documented the deferred EFI Secure Boot certificate warning and its planned resolution.
