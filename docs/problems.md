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

The migration path was subsequently verified by enabling `k8s-worker-01` as a canary. Terraform created VMID 312 from VMID 301 with the administrator and new Ansible public keys, and the Ansible connectivity playbook verified SSH, module execution, fact gathering, and passwordless privilege escalation. The same workflow was then applied to VMIDs 311 and 313. All three Kubernetes VMs are now enabled, and the final Terraform plan reported no infrastructure drift. The old template (VMID 300) remains available temporarily as a rollback source.

## 3. DHCP pool overlapped the static lab address range

Status: resolved on 2026-08-05.

The modem's DHCPv4 pool started at `192.168.0.10` and its configured number of CPE addresses allowed dynamic leases to overlap the static Terraform address range `192.168.0.220-192.168.0.223`.

A phone received `192.168.0.220`, which was also assigned statically to `ansible-controller`. Two devices then claimed the same IPv4 address with different MAC addresses. The workstation could intermittently reach the wrong device, causing an established SSH session to end with `Broken pipe` and subsequent connection attempts to return `Connection refused` even though `sshd` remained active on the controller.

The DHCPv4 number-of-CPE setting was reduced in the modem so that the dynamic pool ends below the lab's static address range. Addresses `192.168.0.220-192.168.0.223` are now excluded from dynamic allocation and remain available for Terraform-managed VMs.

The static range must remain outside the DHCP pool when either side is changed. Existing conflicting leases should be removed or renewed after a pool change before connectivity is considered restored. MAC-based DHCP reservations are not the primary mechanism for these VMs because a recreated Terraform resource can receive a new generated MAC address while retaining its planned static IPv4 address.

## 4. Kubernetes host-preparation role failed on partial and fresh-node states

Status: resolved on 2026-08-06 and verified on `k8s-worker-01`.

The first complete execution of the Kubernetes host-preparation role exposed several assumptions that were not visible during syntax checking. The failures were used to make the role recoverable, check-mode aware, and idempotent before applying it to the remaining cluster nodes.

### Missing containerd configuration directory

After the `containerd` package was installed, the role attempted to deploy `/etc/containerd/config.toml`, but the destination directory did not exist:

```text
Destination directory /etc/containerd does not exist
```

The role now checks the initial containerd state and explicitly creates `/etc/containerd` before rendering the configuration. This also allows a later execution to continue safely after an earlier run stopped partway through.

### Runtime state was not fully reconciled after an interrupted run

The first failed run had already installed packages and written kernel and `sysctl` configuration. A handler scheduled near the end of the play was never reached, so persistent configuration and active runtime state could temporarily differ.

The role now reads the live values of the required Kubernetes `sysctl` parameters and applies only values that differ. This makes recovery independent of whether a previous play reached its handlers and avoids reporting changes when the live values are already correct.

### Read-only containerd checks were skipped in Ansible check mode

Ansible's `command` module skips commands by default under global `--check`. The subsequent assertions therefore received empty registered output and incorrectly reported that the systemd cgroup driver was disabled.

The containerd configuration dump and plugin-status commands are read-only, so they now use `check_mode: false`. They execute even during a check-mode play and provide real output to their assertions without changing the node.

### CRI plugin assertion did not accept padded command output

`ctr plugins list` showed the CRI plugin with status `ok`, but its table output contained trailing whitespace. The original regular expression required `ok` to be immediately followed by the end of the line and rejected the valid row.

The assertion was updated to accept horizontal whitespace after the status while still requiring the expected plugin type, identifier, and `ok` state. The role then verified that the containerd CRI plugin was active.

### Requested Kubernetes package build was unavailable

The initially selected package string did not exist in the configured `pkgs.k8s.io` repository. `apt-cache madison` showed that Kubernetes `1.36.3-1.1` was available, while the available `1.36.2` package used a different packaging revision.

The lab standard was updated to Kubernetes `1.36.3`, and the role now installs and verifies the exact `1.36.3-1.1` versions of `kubelet`, `kubeadm`, and `kubectl`. The packages are placed on APT hold to prevent an unattended version change.

### APT cache refresh prevented an idempotent recap

An unconditional repository-specific cache refresh could report a change on every execution even when the repository configuration was unchanged. This obscured the expected `changed=0` result of the second host-preparation run.

The signing-key and repository tasks now register whether they changed. The cache is refreshed immediately when either input changes; otherwise, a one-hour cache validity window is used. The final repeated play on `k8s-worker-01` reported `ok=37`, `changed=0`, `unreachable=0`, and `failed=0`.
