# Changelog

## 2026-08-10

### Added

- Added the guarded `kubernetes_control_plane` role and playbook with inventory topology validation, partial-state protection, a versioned kubeadm `v1beta4` initialization configuration, and administrator kubeconfig installation.
- Added the guarded `kubernetes_cni` role and playbook for version-pinned Calico `3.32.1` installation through the Tigera Operator, including live cluster network validation and readiness checks.
- Added the guarded `kubernetes_worker` role and serial worker playbook with local and API state consistency checks, short-lived join credentials, post-join validation, and guaranteed token cleanup.
- Added `verify_kubernetes_cluster.yml` for repeatable control-plane, node, system component, cluster DNS, Service ClusterIP, and cross-worker Pod connectivity verification.
- Added a complete environment reproduction guide for a new user, covering Proxmox and template prerequisites, repository adaptation, local secrets, staged controller and node provisioning, controller key generation, scalable worker definitions, Kubernetes bootstrap, and functional verification.
- Documented the tested Proxmox API permission profile: the dedicated `terraform-lab` role uses the `PVEAdmin` privilege set plus `Pool.Audit` within the lab pool, with the source template included in the same permitted scope for cloning.

### Infrastructure

- Initialized `k8s-cp-01` as the single Kubernetes control-plane node with Kubernetes `1.36.3` and the declared Pod and Service networks.
- Installed Calico `3.32.1`; the control-plane node became `Ready`, and CoreDNS and all required Calico components became available.
- Joined `k8s-worker-01` and `k8s-worker-02` through guarded Ansible runs using short-lived kubeadm tokens that were deleted after each successful join.
- Completed the intended three-node cluster topology with management addresses `192.168.0.221-192.168.0.223`.

### Verification

- Repeated the control-plane playbook after initialization and confirmed convergence with `changed=0`; the guarded kubeadm initialization and kubeconfig installation tasks were skipped.
- Repeated the CNI playbook after installation and confirmed convergence with `changed=0`; Calico, the control-plane node, and CoreDNS remained ready.
- Verified each existing worker against its local kubeadm state and Kubernetes API object, then repeated the worker playbook across the complete worker group with `changed=0`.
- Confirmed that all three nodes are `Ready` with Kubernetes `1.36.3`, the expected management addresses, and containerd `2.2.1`.
- Confirmed that Calico node and CSI pods and kube-proxy are running on every Kubernetes node, with CoreDNS, control-plane components, Calico controllers, and the Tigera Operator healthy.
- Ran the functional cluster verification successfully. A temporary server Pod on `k8s-worker-01` and client Pod on `k8s-worker-02` verified cluster DNS, Service ClusterIP routing, and direct cross-worker Pod connectivity; the temporary namespace was removed afterward. The expected recap was `ok=22`, `changed=2`, `unreachable=0`, and `failed=0`, with both changes representing creation and cleanup of test resources.
- Rebooted `k8s-worker-01`, `k8s-worker-02`, and finally the single control-plane node in a controlled sequence. After every restart, all three nodes and required system components returned to readiness and the complete functional verification passed.
- The control-plane recovery test exposed a race between namespace creation and automatic creation of its default ServiceAccount. The verification manifest now creates a dedicated unprivileged ServiceAccount explicitly, disables token mounting, and no longer depends on namespace-controller timing.

## 2026-08-08

### Added

- Added the read-only `verify_kubernetes_hosts.yml` playbook to collect and display normalized Kubernetes node identities.
- Added cluster-wide assertions for expected hostnames and management addresses and for unique hostnames, IPv4 addresses, MAC addresses, and product UUIDs.
- Added the read-only `verify_kubernetes_network.yml` playbook to verify peer routing, expected source addresses, bidirectional ICMP connectivity, and free role-specific Kubernetes ports before bootstrap.
- Added shared API server, containerd CRI socket, and cluster DNS variables together with a versioned kubeadm `v1beta4` initialization configuration template.
- Added `verify_kubeadm_preflight.yml` to validate the single-control-plane topology, kubeadm version, containerd socket, absence of existing cluster state, rendered kubeadm configuration, and kubeadm init preflight in dry-run mode.
- Established a project direction to implement host, network, kubeadm preflight, and post-bootstrap verification primarily as versioned Ansible playbooks so a rebuilt controller can reproduce the validation workflow after cloning the repository.

### Infrastructure

- Enabled and provisioned `k8s-cp-01` (VMID 311) and `k8s-worker-02` (VMID 313) from the current Secure Boot template.
- Completed the planned three-node Kubernetes host topology while retaining `k8s-worker-01` as the previously validated canary.

### Verification

- The initial identity run correctly stopped because unprivileged fact gathering returned `NA` instead of the virtual machine product UUID on every node.
- Enabled privilege escalation for read-only hardware fact gathering and strengthened validation to reject unavailable UUID values.
- Repeated the identity playbook successfully. Every node matched its inventory hostname and management address, all MAC addresses and product UUIDs were unique, and the play recap reported `changed=0`, `unreachable=0`, and `failed=0` across the cluster.
- Ran the pre-bootstrap network playbook across all three nodes. Every node used the expected management address for routes to both peers, all six ICMP directions succeeded, every required role-specific TCP port was free, and each host reported `ok=11`, `changed=0`, `unreachable=0`, and `failed=0`.
- Confirmed that route, ICMP, and listener checks do not require privilege escalation on the supported Ubuntu hosts; stderr validation remains in place so an unavailable listener query cannot be mistaken for a free port.
- Ran `kubeadm init phase preflight --dry-run` through Ansible on `k8s-cp-01` using the rendered initialization configuration. Kubeadm completed successfully, reported that required images would be pulled during a real initialization, and reported use of its temporary dry-run workspace; the play recap reported `ok=13`, `changed=0`, `unreachable=0`, and `failed=0`.
- Ran the connectivity playbook across all Kubernetes nodes and verified SSH access, Ansible module execution, minimal fact gathering, and passwordless privilege escalation.
- Applied the complete Kubernetes host-preparation playbook to `k8s-cp-01`; the initial run reported `changed=16`, and the repeated run reported `ok=37`, `changed=0`, `unreachable=0`, and `failed=0`.
- Applied the same workflow to `k8s-worker-02` with matching initial and idempotent results.
- Ran the host-preparation playbook across the complete `k8s_cluster`. After the time-based APT cache refresh on `k8s-worker-01`, the repeated cluster-wide run reported `ok=37`, `changed=0`, `unreachable=0`, and `failed=0` for every node.
- Confirmed that Terraform reports no changes after provisioning and configuration.

### Full environment rebuild

- Reviewed and applied a Terraform destroy plan containing only the four managed VMs, then verified their removal in Proxmox; the external golden image VMID 301 was retained.
- Disabled the three Kubernetes VM definitions and recreated only `ansible-controller` (VMID 310).
- Verified the replacement controller's new SSH host key, installed Git and Ansible Core, cloned the repository, and successfully ran the local Ansible inspection playbook.
- Generated a new dedicated Ansible SSH key pair on the replacement controller and transferred only its public key to the Terraform workstation.
- Re-enabled and recreated all three Kubernetes VMs with the new controller public key supplied through Cloud-Init.
- Verified Ansible connectivity to the rebuilt nodes and ran the complete Kubernetes host-preparation playbook twice without failures; the repeated run confirmed convergence with no changes.
- Completed the rebuild with a Terraform plan reporting `No changes`, confirming that the recreated infrastructure matches the declared configuration without drift.

## 2026-08-06

### Added

- Selected Kubernetes `1.36.3`, containerd, Calico `3.32.1`, Pod CIDR `10.244.0.0/16`, and Service CIDR `10.96.0.0/12`; the cluster networks do not overlap each other or the host network `192.168.0.0/24`.
- Added the `kubernetes_prepare.yml` playbook, which applies the existing `common` role before the new Kubernetes-specific host preparation role.
- Added the initial `kubernetes_node` role for operating-system validation, kernel modules, networking `sysctl` parameters, swap policy, containerd with the systemd cgroup driver, and CRI checks.
- Added the `pkgs.k8s.io` repository configuration, pinned installation of `kubelet`, `kubeadm`, and `kubectl`, package holds, and installed-version checks.
- Added check-mode guards for operations that require binaries or packages not yet present on a fresh host.
- Made the Kubernetes repository cache refresh idempotent while still forcing a refresh when the signing key or repository definition changes.

### Verification

- Applied the extended `common` role to `k8s-worker-01`; the play completed without problems and reported `changed=1`.
- Ran the extended `common` role a second time on `k8s-worker-01`; the play completed without problems and reported `changed=0`, confirming idempotence.
- Applied the complete `kubernetes_prepare.yml` playbook to the `k8s-worker-01` canary and verified the required kernel modules, networking parameters, disabled swap, containerd systemd cgroup driver, active CRI plugin, Kubernetes repository, exact `1.36.3-1.1` package versions, package holds, and kubelet enablement.
- Ran the complete Kubernetes host-preparation playbook again; the recap reported `ok=37`, `changed=0`, `unreachable=0`, and `failed=0`, confirming idempotence on the canary.

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
