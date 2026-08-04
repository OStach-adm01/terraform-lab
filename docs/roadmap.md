# Roadmap

Goal: build and document a homelab that demonstrates core Junior DevOps / SysOps / SysAdmin skills.

## 1. Terraform + Proxmox

- [x] Prepare an Ubuntu Cloud-Init template.
- [x] Configure the provider and keep secrets outside Git.
- [x] Initialize Terraform and commit the lock file.
- [x] Create and verify `ansible-controller` with an SSH key and a static IP address.
- [ ] Build a VM module and create the Kubernetes nodes.
- [ ] Add IP outputs and infrastructure documentation.

## 2. Ansible

- [ ] Create an inventory and verify the SSH connection.
- [ ] Create a `common` role for updates, packages, users, and basic hardening.
- [ ] Create roles that prepare Kubernetes nodes.
- [ ] Ensure idempotency and run `ansible-lint`.

## 3. Containers

- [ ] Build a simple demo application with Docker.
- [ ] Document the Dockerfile, image tagging, and basic image security.
- [ ] Publish the image locally or to a container registry.

## 4. Kubernetes

- [ ] Create the control plane and worker nodes with Terraform.
- [ ] Configure the cluster with Ansible and kubeadm.
- [ ] Install a CNI, metrics-server, and an ingress controller.
- [ ] Deploy the application: Deployment, Service, Ingress, ConfigMap, Secret, and HPA.

## 5. Quality and Portfolio

- [ ] Add checks: `terraform fmt`/`validate`, `tflint`, `ansible-lint`, and `yamllint`.
- [ ] Extend the README with a diagram, setup instructions, and troubleshooting.
- [ ] Document decisions, limitations, and how to safely destroy the lab.

## IP Address Plan

| Address | Name | Role |
| --- | --- | --- |
| `192.168.0.220/24` | `ansible-controller` | Ansible control node |
| `192.168.0.221/24` | `k8s-cp-01` | Kubernetes control plane |
| `192.168.0.222/24` | `k8s-worker-01` | Kubernetes worker |
| `192.168.0.223/24` | `k8s-worker-02` | Kubernetes worker |

Gateway and DNS: `192.168.0.1`. Check that an address is available before creating a VM; eventually, exclude these addresses from the DHCP pool or reserve them on the router.

## Target Infrastructure

This project has one lab environment, so the Terraform configuration is not split into `environments/` directories.

```text
terraform-lab/
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── secret.auto.tfvars          # ignored by Git
├── modules/
│   └── proxmox-vm/
├── ansible/
├── kubernetes/
└── docs/
```

`main.tf` defines the lab's specific VMs and calls the `proxmox-vm` module. The module contains the reusable Proxmox VM definition.

| VMID | Name | Role | Address |
| ---: | --- | --- | --- |
| 300 | `ubuntu-2404-cloud-template` | Ubuntu 24.04 template | — |
| 310 | `ansible-controller` | Ansible control node | `192.168.0.220/24` |
| 311 | `k8s-cp-01` | Kubernetes control plane | `192.168.0.221/24` |
| 312 | `k8s-worker-01` | Kubernetes worker | `192.168.0.222/24` |
| 313 | `k8s-worker-02` | Kubernetes worker | `192.168.0.223/24` |

All VMs use node `pve`, pool `terraform-lab`, bridge `vmbr0`, storage `local-lvm`, and gateway/DNS `192.168.0.1`.

The SSH private key stays locally in `~/.ssh/` and never enters Git or Terraform state. The path to its public counterpart is configured locally in the Git-ignored `terraform.tfvars` file.
