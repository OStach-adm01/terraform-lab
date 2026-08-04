# Problems

## 1. Initial golden image used legacy firmware

Status: resolved.

The first Ubuntu golden image was created with the `i440fx` machine type and legacy BIOS. It was replaced with the current `ubuntu-2404-cloud-template` (VMID 300), which uses q35 and UEFI.

## 2. EFI disk uses legacy Microsoft Secure Boot certificates

Status: open; intentionally deferred on 2026-08-04.

VMs cloned from the current golden image start with the following Proxmox warning:

```text
EFI disk without 'ms-cert=2023k' option, suggesting that not all UEFI 2023 certificates from Microsoft are enrolled yet.
```

The template uses an EFI disk of type `2m` with pre-enrolled keys. Attempting to configure cloned VMs with EFI type `4m` caused an incompatibility with the source template and prevented VM creation.

The warning does not currently prevent Ubuntu from starting, but leaving Secure Boot enabled with the legacy EFI configuration may cause future boot problems after bootloader or certificate updates. Every new clone would also inherit the same limitation.

Planned resolution:

1. Decide whether Secure Boot is required for this learning lab.
2. If it is not required, explicitly disable pre-enrolled keys while retaining UEFI and q35.
3. If it is required, update or rebuild the golden image with an EFI disk of type `4m`, enroll the Microsoft UEFI 2023 certificates, verify booting, and only then align the Terraform module with the template.
4. Review the Terraform plan before changing or recreating any existing VM.

Do not silence or permanently ignore the warning without making one of these choices.
