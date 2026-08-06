# Changelog

## 2026-08-06

### Added

- Selected Kubernetes `1.36.3`, containerd, Calico `3.32.1`, Pod CIDR `10.244.0.0/16`, and Service CIDR `10.96.0.0/12`; the cluster networks do not overlap each other or the host network `192.168.0.0/24`.
- Added the `kubernetes_prepare.yml` playbook, which applies the existing `common` role before the new Kubernetes-specific host preparation role.
- Added the initial `kubernetes_node` role for operating-system validation, kernel modules, networking `sysctl` parameters, swap policy, containerd with the systemd cgroup driver, and CRI checks.
- Added the `pkgs.k8s.io` repository configuration, pinned installation of `kubelet`, `kubeadm`, and `kubectl`, package holds, and installed-version checks.
- Added check-mode guards for operations that require binaries or packages not yet present on a fresh host.

### Verification

- Applied the extended `common` role to `k8s-worker-01`; the play completed without problems and reported `changed=1`.
- Ran the extended `common` role a second time on `k8s-worker-01`; the play completed without problems and reported `changed=0`, confirming idempotence.

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
- Added the `control_plane`, `workers`, and `k8s_cluster` inventory groups with shared SSH connection variables.
- Added a read-only connectivity playbook that verifies SSH readiness, Ansible module execution, minimal fact gathering, and passwordless privilege escalation.
- Enabled and recreated `k8s-worker-01` (VMID 312) as the first Ansible canary while leaving VMIDs 311 and 313 disabled.
- Added the initial `common` role for package installation, QEMU Guest Agent management, timezone configuration, and NTP synchronization through `systemd-timesyncd`.
- Added a handler that restarts `systemd-timesyncd` only when its managed configuration changes.
- Reduced the modem's DHCPv4 pool so that it no longer overlaps the static Terraform address range `192.168.0.220-192.168.0.223`.

### Verification

- Confirmed that the replacement template boots Ubuntu with Secure Boot enabled and without the legacy EFI certificate warning.
- Confirmed on a disposable clone that Cloud-Init completed, the `ubuntu` password remained locked, password-based SSH authentication was disabled, and no usable SSH authorized keys were inherited.
- Removed the disposable verification clone after testing.
- Confirmed Cloud-Init, static networking, administrator SSH access, EFI `4m` with `ms-cert=2023k`, Secure Boot, and QEMU Guest Agent on the recreated `ansible-controller`.
- Installed Ansible Core on the controller, cloned the project repository, and successfully ran the versioned local inspection playbook.
- Confirmed a clean Terraform plan with only `ansible-controller` enabled.
- Recorded the SSH host key for `k8s-worker-01`, then completed every connectivity playbook task successfully from `ansible-controller`.
- Ran the initial package and QEMU Guest Agent baseline twice on `k8s-worker-01`; both runs completed with `changed=0`.
- Validated the extended `common` role against `k8s-worker-01` in Ansible check and diff modes; the play recap reported `ok=10`, `changed=4`, `unreachable=0`, and `failed=0`.

### Documentation

- Marked the legacy Microsoft Secure Boot certificate problem as resolved.
- Updated the golden image specification and current infrastructure inventory.
- Documented the DHCP address conflict and the corrected separation between the dynamic and static address ranges.

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
