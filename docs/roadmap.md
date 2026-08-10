# Roadmap

Goal: build and document a homelab for learning and understanding the technologies used to provision, configure, operate, and validate modern infrastructure.

Each phase ends with a verification gate. A component is considered complete only after its configuration and observed behavior have both been checked.

## 1. Terraform and Proxmox

- [x] Prepare an Ubuntu 24.04 Cloud-Init template.
- [x] Configure the Proxmox provider and keep secrets outside Git.
- [x] Initialize Terraform and commit the dependency lock file.
- [x] Build a reusable `proxmox-vm` module.
- [x] Create and verify `ansible-controller` with a static IP address and administrator SSH access.
- [x] Add Terraform outputs for VM IPv4 addresses.
- [x] Add separate administrator and Ansible controller SSH keys for Ansible-managed VMs.
- [x] Provision the future Kubernetes nodes as unconfigured Ubuntu VMs for the initial infrastructure test.
- [x] Replace the legacy EFI template with a Secure Boot template using EFI `4m` and Microsoft UEFI 2023 certificates.
- [x] Add an explicit VM enable switch and retain the disabled Kubernetes definitions for later recreation.
- [ ] Verify Cloud-Init, hostnames, networking, SSH, QEMU Guest Agent, and passwordless sudo on every new VM.
- [x] Confirm a clean Terraform plan without drift after provisioning.
- [x] Destroy and rebuild all Terraform-managed VMs in controlled stages, rotate the Ansible controller SSH key, reconverge the Kubernetes hosts, and confirm a final clean Terraform plan.
- [ ] Complete the Terraform and infrastructure documentation.

Verification gate: all four VMs are reachable with the expected identity and configuration, and Terraform reports no changes.

## 2. Ansible Connectivity and Baseline

- [x] Verify Ansible locally on `ansible-controller` using a minimal inventory and inspection playbook.
- [x] Create a dedicated SSH key pair for `ansible-controller`.
- [x] Add `control_plane`, `workers`, and `k8s_cluster` groups to the inventory.
- [x] Provision `k8s-worker-01` as a canary and verify SSH, Ansible modules, minimal facts, and passwordless privilege escalation.
- [ ] Record and verify SSH host keys for every managed node.
- [x] Verify SSH connectivity and `ansible.builtin.ping` from `ansible-controller` to every managed node.
- [x] Gather and inspect facts from all managed nodes.
- [x] Verify passwordless privilege escalation with `become` on all managed nodes.
- [ ] Extend the `common` role with an update policy, user management, and basic hardening.
- [x] Add the initial `common` role tasks for base packages and QEMU Guest Agent management.
- [x] Extend the `common` role with timezone and `systemd-timesyncd` configuration.
- [x] Apply the extended `common` role to `k8s-worker-01` (`changed=1`, no failures).
- [x] Run the `common` role a second time and confirm `changed=0`.
- [x] Review the extended role on `k8s-worker-01` with Ansible check and diff modes (`ok=10`, `changed=4`, `unreachable=0`, `failed=0`).

Verification gate: every managed node is reachable through Ansible, privilege escalation works, and the common configuration is idempotent.

## 3. Container Application

- [ ] Build a small demo application suitable for deployment to Kubernetes.
- [ ] Create a minimal Dockerfile and `.dockerignore`.
- [ ] Build and run the image locally.
- [ ] Add a health check and test the application through the container port.
- [ ] Use explicit, versioned image tags instead of relying only on `latest`.
- [ ] Review image layers, size, base image choice, and non-root execution.
- [ ] Choose a container registry and publish the versioned image.
- [ ] Verify that the image can be pulled independently of the build environment.

Verification gate: the versioned image runs locally, passes its health check, and is available from the chosen registry.

## 4. Kubernetes Host Preparation with Ansible

- [x] Select and document Kubernetes `1.36.3`, containerd, Calico `3.32.1`, Pod CIDR `10.244.0.0/16`, and Service CIDR `10.96.0.0/12`.
- [x] Confirm that the Pod and Service networks do not overlap each other or the host network `192.168.0.0/24`.
- [x] Verify expected and unique hostnames, management addresses, MAC addresses, and `product_uuid` values on all Kubernetes nodes through a read-only Ansible playbook.
- [x] Verify bidirectional routing and ICMP connectivity between every Kubernetes node and confirm that the required pre-bootstrap ports are free through a repeatable Ansible playbook.
- [x] Create an Ansible role for required kernel modules and `sysctl` settings.
- [x] Configure swap according to the selected kubelet policy.
- [x] Install and configure `containerd` with the systemd cgroup driver and verify that its CRI plugin is active.
- [x] Add the Kubernetes package repository and install pinned `1.36.3-1.1` versions of `kubelet`, `kubeadm`, and `kubectl`.
- [x] Prevent unintended Kubernetes package upgrades with APT holds.
- [x] Run and review `kubeadm init phase preflight --dry-run` through Ansible using the versioned kubeadm configuration intended for cluster initialization.
- [x] Run the host-preparation roles a second time on the `k8s-worker-01` canary and confirm `changed=0`.
- [x] Apply and verify the host-preparation roles on `k8s-cp-01` and `k8s-worker-02`.
- [x] Run the host-preparation playbook across `k8s_cluster` and confirm `ok=37`, `changed=0`, `unreachable=0`, and `failed=0` on every node.

Verification gate: every node satisfies the selected Kubernetes version's prerequisites and the preparation roles are idempotent.

## 5. Kubernetes Cluster Bootstrap

- [x] Bootstrap the single control-plane node with `kubeadm` through a guarded and idempotent Ansible role.
- [x] Configure kubeconfig for the intended administrative user.
- [x] Install Calico `3.32.1` through the Tigera Operator using a guarded Ansible role.
- [x] Verify the control-plane components, Calico components, and CoreDNS.
- [x] Join both worker nodes serially through Ansible using short-lived kubeadm tokens and guaranteed token cleanup.
- [x] Confirm that all nodes reach the `Ready` state.
- [x] Verify direct Pod-to-Pod connectivity across the two worker nodes through a repeatable Ansible playbook.
- [x] Verify DNS resolution and Service ClusterIP routing from inside a Pod.
- [x] Reboot both workers and the single control-plane node in a controlled sequence and confirm full cluster recovery after every restart.

Verification gate: the control plane and both workers are healthy, cluster networking and DNS work, and the cluster survives controlled node reboots.

## 6. Cluster Services

- [ ] Install and verify metrics-server.
- [ ] Install an ingress controller.
- [ ] Choose and document how services are exposed on the home network: NodePort, MetalLB, or another explicit method.
- [ ] Configure the selected exposure method.
- [ ] Verify ingress routing from a client outside the cluster.

Verification gate: resource metrics are available and an ingress endpoint is reachable from the home network.

## 7. Application Deployment

- [ ] Create a dedicated Namespace for the demo application.
- [ ] Add Deployment and Service manifests.
- [ ] Add ConfigMap and Secret usage without committing secret values.
- [ ] Configure readiness and liveness probes.
- [ ] Configure CPU and memory requests and limits.
- [ ] Add an Ingress resource.
- [ ] Add an HPA based on available metrics.
- [ ] Verify rollout, service discovery, ingress access, configuration injection, and scaling behavior.

Verification gate: the application is reachable through ingress, handles configuration safely, reports healthy probes, and scales under a controlled test load.

## 8. Quality, Lifecycle, and Portfolio

- [ ] Add repeatable checks for `terraform fmt`, `terraform validate`, `tflint`, `ansible-lint`, and `yamllint`.
- [ ] Add validation for Kubernetes manifests.
- [ ] Decide whether checks run through a local script, Makefile, pre-commit hooks, or CI.
- [x] Provide a documented Ansible verification sequence that can be run after cloning the repository onto a rebuilt controller.
- [x] Add a project overview, current infrastructure status, and repository structure to the README.
- [x] Add a diagram of the current and planned infrastructure architecture.
- [x] Document the current key engineering decisions.
- [ ] Add prerequisites, setup, verification, and troubleshooting instructions to the README.
- [ ] Extend the architecture diagram with Kubernetes networking and application traffic.
- [ ] Document accepted risks and current limitations.
- [ ] Document backup and recovery procedures, including the single-control-plane limitation.
- [ ] Document safe upgrade procedures for Terraform providers, Ansible dependencies, and Kubernetes components.
- [x] Document how a new user can adapt the repository and reproduce the complete lab in a separate Proxmox environment.

The complete destroy-and-rebuild workflow has been tested successfully. The
environment reproduction guide documents how a new user can adapt the
repository, provision a separate lab, and execute the complete Ansible
verification and bootstrap sequence from a fresh controller.

Verification gate: a new reader can understand, reproduce, validate, operate, and troubleshoot the lab from the repository documentation.

## Current and Planned Infrastructure

This project has one lab environment, so the Terraform configuration is not split into `environments/` directories.

| VMID | Name | Current role | Address | Resources | Status |
| ---: | --- | --- | --- | --- | --- |
| 300 | `ubuntu-2404-cloud-template` | Legacy Ubuntu 24.04 template | — | 2 vCPU, 2 GB RAM, 20 GB disk | Retained temporarily as a rollback source; EFI `2m` warning applies |
| 301 | `ubuntu-2404-cloud-template-uefi2023` | Current Ubuntu 24.04 template | — | 2 vCPU, 2 GB RAM, 20 GB disk | Verified; EFI `4m`, Secure Boot, Microsoft UEFI 2023 certificates |
| 310 | `ansible-controller` | Ansible control node | `192.168.0.220/24` | 2 vCPU, 2 GB RAM, 20 GB disk | Recreated from VMID 301; verified; Ansible Core operational |
| 311 | `k8s-cp-01` | Kubernetes control plane | `192.168.0.221/24` | 2 vCPU, 2 GB RAM, 20 GB disk | Kubernetes `1.36.3`; Calico `3.32.1`; `Ready`; bootstrap and CNI roles verified and idempotent |
| 312 | `k8s-worker-01` | Kubernetes worker | `192.168.0.222/24` | 1 vCPU, 2 GB RAM, 20 GB disk | Joined through Ansible; `Ready`; worker role verified and idempotent |
| 313 | `k8s-worker-02` | Kubernetes worker | `192.168.0.223/24` | 1 vCPU, 2 GB RAM, 20 GB disk | Joined through Ansible; `Ready`; worker role verified and idempotent |

All current and planned Terraform-managed instances use node `pve`, pool `terraform-lab`, bridge `vmbr0`, storage `local-lvm`, and gateway/DNS `192.168.0.1`.

Terraform creates reachable Ubuntu VMs, and Ansible configures their operating systems and bootstraps Kubernetes. The single control-plane node and both workers are enabled and `Ready`. Kubernetes `1.36.3`, Calico `3.32.1`, cluster DNS, Service ClusterIP routing, and direct cross-worker Pod connectivity have been verified through versioned Ansible workflows. Repeated control-plane, CNI, and worker configuration runs reported no changes, and Terraform subsequently reported no infrastructure drift.

## Network and Address Plan

| Address | Name | Purpose |
| --- | --- | --- |
| `192.168.0.220/24` | `ansible-controller` | Ansible control node |
| `192.168.0.221/24` | `k8s-cp-01` | Kubernetes control plane |
| `192.168.0.222/24` | `k8s-worker-01` | Kubernetes worker |
| `192.168.0.223/24` | `k8s-worker-02` | Kubernetes worker |

Gateway and DNS are `192.168.0.1`. The modem's DHCPv4 pool was reduced so that it ends below the Terraform-managed static range. Addresses `192.168.0.220-192.168.0.223` are therefore excluded from dynamic allocation; this separation must be preserved if either range is changed later.

The Kubernetes Pod CIDR is `10.244.0.0/16` and the Service CIDR is `10.96.0.0/12`. Neither network overlaps the host network `192.168.0.0/24` or the other cluster network.

## SSH Trust Model

- The administrator private key stays on the workstation.
- The Ansible private key stays on `ansible-controller`.
- Private keys never enter Git or Terraform configuration. Secrets and workstation-specific paths stay in local variable files ignored by Git.
- Every VM trusts the administrator public key.
- Only VMs marked with `ansible_managed = true` trust the Ansible controller public key.
- Public-key paths are configured locally in the Git-ignored `terraform.tfvars` file.

## Target Repository Structure

```text
terraform-lab/
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── lab.tfvars
├── terraform.tfvars.example       # planned, contains no secrets
├── terraform.tfvars               # local and ignored by Git
├── modules/
│   └── proxmox-vm/
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   ├── playbooks/
│   └── roles/
│       ├── common/
│       ├── kubernetes_node/
│       ├── kubernetes_control_plane/
│       ├── kubernetes_cni/
│       └── kubernetes_worker/
├── kubernetes/                    # planned manifests and configuration
└── docs/
```

`main.tf` defines the lab-specific VMs and calls the reusable `proxmox-vm` module. Versioned `lab.tfvars` contains non-secret VM sizing and addressing. Local `terraform.tfvars` contains secret or workstation-specific values and is ignored by Git.
