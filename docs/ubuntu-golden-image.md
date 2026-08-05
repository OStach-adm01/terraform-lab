# Ubuntu Golden Image

The current golden image is an Ubuntu 24.04 Cloud-Init template used as the source for Terraform-managed VMs.

## Proxmox configuration

- Name: `ubuntu-2404-cloud-template-uefi2023`
- VMID: 301
- Pool: `terraform-lab`
- BIOS: OVMF (UEFI)
- Machine: q35
- EFI disk: `4m`, pre-enrolled keys enabled, Microsoft UEFI 2023 certificates enrolled (`ms-cert=2023k`)
- CPU: 2 cores, type `host`
- Memory: 2048 MiB
- System disk: 20 GiB using `virtio-scsi-single`
- Network: VirtIO on `vmbr0`; DHCP is used only while preparing or testing the template
- Display: serial console on `serial0`

VMID 301 was selected because identifiers in the 100 and 200 series are already used by other Active Directory and Terraform learning environments.

## Installed packages and services

The image is intentionally minimal. It includes:

- `qemu-guest-agent`
- `cloud-guest-utils`
- `ca-certificates`
- `bash-completion`
- `openssh-server`

Cloud-Init, QEMU Guest Agent, and OpenSSH are enabled.

## Template preparation and verification

Before conversion to a template:

- the local Cloud-Init password was removed and the `ubuntu` password was locked;
- embedded user and root SSH authorized keys were removed;
- Cloud-Init state, logs, and machine ID were cleaned;
- SSH host keys were removed so each clone generates a unique host identity;
- the obsolete EFI vars disk was deleted.

A disposable clone confirmed that Cloud-Init completed, Secure Boot was enabled, the EFI certificate warning was absent, password-based SSH authentication was disabled, and no usable SSH authorized keys were inherited. Terraform supplies the target username and public keys when it creates each VM.
