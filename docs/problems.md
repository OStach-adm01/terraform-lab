# Problems

## 1. Initial golden image used legacy firmware

Status: resolved.

The first Ubuntu golden image was created with the `i440fx` machine type and legacy BIOS. It was replaced with an Ubuntu 24.04 template using q35 and UEFI.

## 2. EFI disk uses legacy Microsoft Secure Boot certificates

Status: replacement template resolved on 2026-08-05; migration of existing VMs in progress.

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

### Selected migration

The migration will be performed in stages:

1. Temporarily disable the three Kubernetes VM definitions while retaining their configuration for later reuse.
2. Review a new Terraform plan that replaces only `ansible-controller` and removes the currently unused Kubernetes nodes.
3. Recreate `ansible-controller` from VMID 301 and verify Cloud-Init, networking, administrator SSH access, Secure Boot, and QEMU Guest Agent.
4. Generate a new Ansible SSH key pair on the new controller. Its private key remains only on `ansible-controller`.
5. Copy the new public key to the workstation path configured by `ansible_ssh_public_key_path`.
6. Re-enable the Kubernetes VM definitions so Terraform creates them from VMID 301 with the administrator and new Ansible public keys.
7. Verify the final Terraform plan before applying it, then validate SSH host keys and Ansible connectivity for every recreated node.

The old template (VMID 300) remains available as a temporary rollback source until the migration and post-provisioning checks are complete.
