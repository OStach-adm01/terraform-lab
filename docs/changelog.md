# Changelog

## 2026-08-05

### Changed

- Created `ubuntu-2404-cloud-template-uefi2023` (VMID 301) from the previous Ubuntu 24.04 golden image.
- Replaced the legacy EFI vars disk with EFI type `4m`, pre-enrolled keys, and Microsoft UEFI 2023 certificates (`ms-cert=2023k`).
- Removed the template's Cloud-Init password, embedded SSH authorized keys, Cloud-Init instance state, machine ID, and SSH host keys before conversion to a template.
- Updated the Terraform VM defaults to clone VMID 301 and explicitly configure EFI type `4m`.
- Extended the `proxmox-vm` module input contract and resource configuration with the EFI disk type.
- Added an `enabled` attribute to VM definitions and filtered the module instances so planned VMs can remain versioned without being provisioned.
- Disabled and removed the three unconfigured Kubernetes VMs while retaining their definitions for later recreation.
- Recreated `ansible-controller` (VMID 310) from VMID 301 after adding the source template to the `terraform-lab` pool.
- Rotated the Ansible controller SSH key pair; the new private key remains on the controller and only its public key is referenced by the local Terraform configuration.

### Verification

- Confirmed that the replacement template boots Ubuntu with Secure Boot enabled and without the legacy EFI certificate warning.
- Confirmed on a disposable clone that Cloud-Init completed, the `ubuntu` password remained locked, password-based SSH authentication was disabled, and no usable SSH authorized keys were inherited.
- Removed the disposable verification clone after testing.
- Confirmed Cloud-Init, static networking, administrator SSH access, EFI `4m` with `ms-cert=2023k`, Secure Boot, and QEMU Guest Agent on the recreated `ansible-controller`.
- Installed Ansible Core on the controller, cloned the project repository, and successfully ran the versioned local inspection playbook.
- Confirmed a clean Terraform plan with only `ansible-controller` enabled.

### Documentation

- Marked the legacy Microsoft Secure Boot certificate problem as resolved.
- Updated the golden image specification and current infrastructure inventory.

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
