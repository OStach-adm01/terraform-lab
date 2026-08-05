# Problems

## 1. Initial golden image used legacy firmware

Status: resolved.

The first Ubuntu golden image was created with the `i440fx` machine type and legacy BIOS. It was replaced with an Ubuntu 24.04 template using q35 and UEFI.

## 2. EFI disk uses legacy Microsoft Secure Boot certificates

Status: resolved on 2026-08-05.

VMs cloned from the previous golden image (VMID 300) started with the following Proxmox warning:

```text
EFI disk without 'ms-cert=2023k' option, suggesting that not all UEFI 2023 certificates from Microsoft are enrolled yet.
```

The previous template used an EFI disk of type `2m` with pre-enrolled keys. Configuring its clones with EFI type `4m` caused an incompatibility with the source template and prevented VM creation.

Secure Boot remains enabled. A replacement golden image named `ubuntu-2404-cloud-template-uefi2023` was created as VMID 301 with an EFI disk of type `4m`, pre-enrolled keys, and the `ms-cert=2023k` marker. The previous EFI disk was removed before the VM was converted to a template.

The replacement template and a disposable clone were verified before updating Terraform:

- Ubuntu started without the EFI certificate warning.
- `mokutil --sb-state` reported `SecureBoot enabled`.
- Cloud-Init completed on the clone.
- Password authentication remained disabled and the `ubuntu` password was locked.
- No SSH public keys were embedded in the template; empty `authorized_keys` files created by Cloud-Init do not grant access.

Terraform now clones VMID 301 and explicitly configures EFI type `4m`.

### Impact on existing Terraform-managed VMs

The first Terraform plan after changing the template reported:

```text
Plan: 4 to add, 0 to change, 4 to destroy.
```

Both `clone.vm_id` changing from 300 to 301 and `efi_disk.type` changing from `2m` to `4m` force resource replacement. Applying that plan without preparation would therefore recreate `ansible-controller` and all three future Kubernetes nodes. Recreated VMs receive new disks, MAC addresses, SSH host keys, machine identities, and other instance-specific data even when their VMIDs and static IPv4 addresses remain unchanged.

The replacement of `ansible-controller` also removes the Ansible private key stored inside that VM. This is intentional for the selected migration, but the new controller must receive a newly generated key pair before any Ansible-managed VM is provisioned again.

### Completed migration

The migration was completed in controlled stages:

1. An `enabled` attribute was added to the root VM definitions and the module `for_each` was restricted to enabled VMs.
2. The three Kubernetes VM definitions were disabled but retained in `lab.tfvars`; Terraform removed VMIDs 311-313.
3. The first attempt to recreate `ansible-controller` failed because VMID 301 was not a member of the `terraform-lab` pool and the restricted API token did not have `VM.Clone` permission on the source template.
4. VMID 301 was added to the pool, a fresh plan was reviewed, and `ansible-controller` was recreated as VMID 310 from the replacement template.
5. Cloud-Init, static networking, administrator SSH access, EFI `4m` with `ms-cert=2023k`, Secure Boot, and QEMU Guest Agent were verified on the new controller.
6. Ansible Core was installed, the repository was cloned from GitHub, and the versioned local inspection playbook completed successfully.
7. A new Ansible SSH key pair was generated on the controller. Its private key remains there, while its public key was copied to the workstation path configured by `ansible_ssh_public_key_path`.
8. A final Terraform plan reported no changes with the Kubernetes VM definitions still disabled.

When Kubernetes work resumes, setting `enabled = true` will recreate VMIDs 311-313 from VMID 301 with the administrator and new Ansible public keys. The old template (VMID 300) remains available temporarily as a rollback source.
