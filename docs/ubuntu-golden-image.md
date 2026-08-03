# summary of ubuntu golden image

name: ubuntu-2404-cloud-template
vmid 300 as 100+ and 200+ were used for ad and terraform learning
pool: terraform-lab
bios: ovmf (uefi); enabled efi disk
machine: q35
cores: 2
memory: 2048
disk: 20g, virtio-scsi-single
network: virtio vmbr0; dhcp for template only
vga: serial0 for .js cli

as for packets - i want to make this template as minimalistic as possible
installed:
qemu-guest-agent 
cloud-guest-utils 
ca-certificates 
bash-completion
openssh-server

enabled: cloud-init, qemu-guest-agent, openssh-server