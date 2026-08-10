# Reproduce the Lab on a New Machine

This guide describes how a new user can clone the repository, adapt it to a
separate Proxmox environment, provision the virtual machines, and build the
three-node Kubernetes cluster.

The repository automates virtual machines and their configuration. It does not
install Proxmox VE or create the source Cloud-Init template automatically.

The commands below use ordinary interactive `terraform plan` and
`terraform apply` steps to keep the learning workflow straightforward. For
more controlled infrastructure changes, the safer practice is to save the plan
under `/tmp`, inspect it, and apply that exact file:

```bash
terraform plan \
  -var-file=lab.tfvars \
  -out=/tmp/terraform-lab.tfplan
terraform show /tmp/terraform-lab.tfplan
terraform apply /tmp/terraform-lab.tfplan
```

Saved plan files can contain sensitive values. Never store them in the
repository or share their contents.

## Resulting environment

With the repository defaults, Terraform creates:

| VMID | Name | Default address | Purpose |
| ---: | --- | --- | --- |
| 310 | `ansible-controller` | `192.168.0.220/24` | Ansible control node |
| 311 | `k8s-cp-01` | `192.168.0.221/24` | Kubernetes control plane |
| 312 | `k8s-worker-01` | `192.168.0.222/24` | Kubernetes worker |
| 313 | `k8s-worker-02` | `192.168.0.223/24` | Kubernetes worker |

The final cluster uses Kubernetes `1.36.3`, containerd, Calico `3.32.1`, Pod
CIDR `10.244.0.0/16`, and Service CIDR `10.96.0.0/12`.

Do not use the default VMIDs or addresses without first confirming that they
are free in the target environment.

## Adding more workers

The Terraform VM map, Ansible `workers` inventory group, serial worker-join
playbook, and Calico DaemonSets are designed to support more than the two
workers included in the default topology. For each additional worker:

- add a unique enabled and `ansible_managed` VM entry to `lab.tfvars`;
- assign a free VMID, static address, and sufficient compute resources;
- add the matching generated hostname and address to the `workers` group in
  `ansible/inventory/hosts.yml`;
- include the new host in the connectivity, identity, network, preparation,
  and worker-join runs described below.

The cluster verification playbook requires every registered Kubernetes node to
match `k8s_cluster` inventory. Its functional cross-worker test currently uses
the first two hosts in the `workers` group, so it confirms cluster networking
but does not test every possible worker pair. Available Proxmox capacity,
control-plane resources, and the selected Pod network remain practical scaling
limits.

## 1. Prepare the workstation

The workstation is the machine from which Terraform connects to Proxmox. It
requires:

- Git;
- Terraform compatible with the versioned provider lock file;
- OpenSSH client tools;
- network access to the Proxmox API and the planned VM addresses;
- outbound HTTPS access for Terraform provider installation;
- a Proxmox API token with the permissions required to clone and manage VMs;
- an administrator SSH key pair.

Fork the repository when the target environment requires different versioned
VM definitions or inventory. Clone the repository that will remain accessible
to the future Ansible controller:

```bash
git clone <repository-url>
cd terraform-lab
```

`<repository-url>` may be the original public repository when its versioned
configuration can be used unchanged. Otherwise, use the URL of the user's fork.

Review the current branch and working tree before making local adaptations:

```bash
git status --short
git log --oneline -5
```

## 2. Prepare Proxmox and the golden image

The target Proxmox environment must provide:

- a Proxmox node;
- a pool available to the API token;
- VM storage and EFI storage;
- a Linux bridge connected to the intended network;
- an Ubuntu 24.04 Cloud-Init template with QEMU Guest Agent enabled;
- free VMIDs and static addresses for all four VMs.

The controller and Kubernetes nodes require working DNS and outbound HTTPS for
APT repositories, the source repository, version-pinned Calico manifests, and
container images.

The current defaults expect node `pve`, pool `terraform-lab`, storage
`local-lvm`, bridge `vmbr0`, and template VMID 301. The reference template uses
q35, OVMF, an EFI `4m` vars disk, pre-enrolled keys, and Microsoft UEFI 2023
certificates. See [Ubuntu golden image](ubuntu-golden-image.md) for its complete
specification and verification steps.

Verify a disposable clone before Terraform uses the template. At minimum,
confirm Cloud-Init completion, QEMU Guest Agent operation, unique SSH host-key
generation, disabled password authentication, and access through an injected
public key.

STOP if the template contains a private key, inherited authorized key, reusable
machine identity, or working password.

### Proxmox API permissions used by this lab

The verified environment was provisioned with a dedicated Proxmox API token
using the custom `terraform-lab` role. That role was created with the `PVEAdmin`
privilege set plus `Pool.Audit` and assigned within the `terraform-lab` pool.
The source template VMID 301 was also added to that pool so the token could
clone it; without access to the source template, cloning failed with a
`VM.Clone` permission error.

This is the permission profile that was used successfully to create, inspect,
update, start, stop, and destroy the Terraform-managed VMs in this project. It
is recorded as a tested prerequisite, not as a formally proven minimum
privilege set. A user reproducing the lab with another pool name must apply the
equivalent role and API-token access to that pool and ensure the selected source
template is included in the permitted scope.

## 3. Adapt the repository to the target environment

Review `locals.vm_defaults` in `main.tf`. Change values that do not match the
target Proxmox installation:

- `node_name`;
- `pool_id`;
- `template_vm_id`;
- both `datastore_id` values;
- `network_bridge`;
- `ipv4_gateway`;
- `dns_servers` and `dns_domain`.

Review `lab.tfvars` and assign free VMIDs, addresses, CPU counts, and memory.
Keep the controller and control plane at 2 vCPUs and 2 GiB RAM or higher. The
current workers use 1 vCPU and 2 GiB RAM each.

Update `ansible/inventory/hosts.yml` so every `ansible_host` matches the address
selected in `lab.tfvars`. If the host network changes, confirm that it does not
overlap either Kubernetes network in
`ansible/inventory/group_vars/k8s_cluster.yml`.

The automation currently assumes the guest account is named `devops`. That name
also appears in the Ansible private-key path, kubeconfig paths, and
control-plane role defaults. Using another account requires a coordinated
change across Terraform, inventory, and the Kubernetes roles; changing only
the module username is insufficient.

Run formatting after intentional Terraform edits:

```bash
terraform fmt -recursive
```

Review, commit, and push the non-secret adaptations before creating the
controller. The controller must later clone the same commit containing the
selected VM definitions, inventory, and cluster variables:

```bash
git diff --check
git status --short
git add main.tf lab.tfvars ansible/inventory
git commit -m "Adapt lab environment"
git push
```

Do not add `terraform.tfvars`, Terraform state, saved plans, or any key file.

## 4. Configure local Terraform inputs

Create the Git-ignored `terraform.tfvars` on the workstation. Never commit this
file:

```hcl
proxmox_api_token = "<user@realm!token=secret>"
proxmox_endpoint  = "https://<proxmox-address>:8006/"

admin_ssh_public_key_path = "/absolute/path/to/admin-key.pub"
ansible_ssh_public_key_path = "/absolute/path/to/ansible-controller.pub"
```

Generate an administrator key if a dedicated key is not already available:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_terraform_lab
```

The Ansible controller does not exist yet, but Terraform evaluates both public
key paths during planning. For the controller-only stage, create the configured
Ansible public-key file as a temporary copy of the administrator public key:

```bash
install -m 0644 \
  ~/.ssh/id_ed25519_terraform_lab.pub \
  /absolute/path/to/ansible-controller.pub
```

This temporary key is not injected into `ansible-controller`, because that VM
is not marked `ansible_managed`. It will be replaced with the controller's real
public key before any Kubernetes node is created.

Initialize and validate Terraform:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
```

STOP if a secret, private key, state file, or local variable file appears in
`git status --short`.

## 5. Create only the Ansible controller

Temporarily disable every Kubernetes VM in `lab.tfvars` while retaining its
complete definition. In each `k8s_cp_01`, `k8s_worker_01`, and
`k8s_worker_02` object, change only the existing field to:

```hcl
enabled = false
```

Do the same for any additional Kubernetes worker definition.

Create and review a normal plan:

```bash
terraform plan -var-file=lab.tfvars
```

Expected default result:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

The only planned resource must be `ansible-controller`. Review its VMID,
address, template, storage, bridge, and administrator public key before
applying:

```bash
terraform apply -var-file=lab.tfvars
```

Wait for the VM and Cloud-Init. From its Proxmox console:

```bash
cloud-init status --wait
sudo systemctl is-active qemu-guest-agent
```

Connect to the controller:

```bash
ssh devops@<controller-address>
```

STOP on failed Cloud-Init or an unavailable QEMU Guest Agent.

## 6. Configure the Ansible controller key

On `ansible-controller`, install the required tools and clone the repository:

```bash
sudo apt-get update
sudo apt-get install -y git ansible-core
git clone <repository-url>
cd ~/terraform-lab/ansible
ansible-playbook playbooks/inspect.yml
```

Use the same repository URL and reviewed commit that were prepared on the
workstation.

Generate the dedicated key pair used only for Ansible-managed VMs:

```bash
ssh-keygen \
  -t ed25519 \
  -f /home/devops/.ssh/id_ed25519_ansible \
  -C ansible-controller
```

The private key must remain on the controller. From the workstation, copy only
the public key to a temporary path:

```bash
scp devops@<controller-address>:/home/devops/.ssh/id_ed25519_ansible.pub \
  /tmp/ansible-controller.pub
```

Replace the temporary public-key file referenced by
`ansible_ssh_public_key_path`:

```bash
install -m 0644 \
  /tmp/ansible-controller.pub \
  /absolute/path/to/ansible-controller.pub
```

STOP if the destination is not the exact path from the local
`terraform.tfvars`.

## 7. Provision the Kubernetes nodes

On the workstation, enable the control plane and every intended worker in
`lab.tfvars`. In every Kubernetes VM object, change only the existing field
back to:

```hcl
enabled = true
```

Create and review a normal plan:

```bash
terraform plan -var-file=lab.tfvars
```

The plan must add exactly the control plane and every worker declared by the
user; with repository defaults, this means two workers. It must report no
change to the existing controller. Verify that every Kubernetes node receives
both the administrator public key and the new Ansible controller public key.

Expected result with the default topology:

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

Apply after confirming that the displayed apply plan has the same scope:

```bash
terraform apply -var-file=lab.tfvars
```

Wait for Cloud-Init and QEMU Guest Agent on every node. From
`ansible-controller`, connect once to every node with the dedicated key:

```bash
ssh -i /home/devops/.ssh/id_ed25519_ansible devops@<control-plane-address> true
ssh -i /home/devops/.ssh/id_ed25519_ansible devops@<worker-01-address> true
ssh -i /home/devops/.ssh/id_ed25519_ansible devops@<worker-02-address> true
```

Repeat the worker connection for every additional inventory host.

## 8. Run Ansible connectivity gates

From `~/terraform-lab/ansible` on the controller:

```bash
ansible-playbook playbooks/connectivity.yml
ansible-playbook playbooks/verify_kubernetes_hosts.yml
ansible-playbook playbooks/verify_kubernetes_network.yml
```

STOP on an unreachable host, identity mismatch, unexpected source address,
missing peer connectivity, or occupied required pre-bootstrap port.

## 9. Prepare every Kubernetes host

Apply the common baseline and Kubernetes prerequisites:

```bash
ansible-playbook playbooks/kubernetes_prepare.yml
```

The playbook configures and verifies kernel modules, sysctl values, swap
policy, containerd, CRI, pinned Kubernetes packages, and package holds.

Run the kubeadm dry-run gate:

```bash
ansible-playbook playbooks/verify_kubeadm_preflight.yml
```

Expected result on the control plane: `ok=13`, `changed=0`, `unreachable=0`,
and `failed=0`.

## 10. Bootstrap the control plane

Run the control-plane role with bootstrap disabled first:

```bash
ansible-playbook playbooks/kubernetes_control_plane.yml
```

After reviewing the rendered kubeadm configuration, enable initialization with
a JSON boolean:

```bash
ansible-playbook playbooks/kubernetes_control_plane.yml \
  --extra-vars '{"kubernetes_control_plane_bootstrap_enabled": true}'
```

Do not use `kubeadm reset` or manually remove partial state after a failure;
inspect the reported state markers and kubeadm output first.

## 11. Install Calico

Run the read-only gate:

```bash
ansible-playbook playbooks/kubernetes_cni.yml
```

Prepare and review the pinned manifests:

```bash
ansible-playbook playbooks/kubernetes_cni.yml \
  --extra-vars '{"kubernetes_cni_prepare_enabled": true}'
```

Install Calico:

```bash
ansible-playbook playbooks/kubernetes_cni.yml \
  --extra-vars '{"kubernetes_cni_install_enabled": true}'
```

The installation run waits for the control-plane node, Calico, and CoreDNS to
become ready.

## 12. Join the workers

Run the worker state gate without joining:

```bash
ansible-playbook playbooks/kubernetes_workers.yml
```

Join both workers serially using short-lived tokens:

```bash
ansible-playbook playbooks/kubernetes_workers.yml \
  --extra-vars '{"kubernetes_worker_join_enabled": true}'
```

The role waits for each node to become `Ready` and deletes its temporary token.

## 13. Verify the finished environment

Run the read-only verification first:

```bash
ansible-playbook playbooks/verify_kubernetes_cluster.yml
```

Expected result: `changed=0`. Then run the functional verification:

```bash
ansible-playbook playbooks/verify_kubernetes_cluster.yml \
  --extra-vars '{"kubernetes_cluster_verification_enabled": true}'
```

Expected result for the default topology: `ok=22`, `changed=2`,
`unreachable=0`, and `failed=0`. The test checks that every inventory node is
registered and `Ready`, Kubernetes API readiness, system component rollouts,
DNS, Service ClusterIP routing, and direct Pod connectivity between the first
two workers. The two changes represent temporary resource creation and cleanup.

On the workstation, verify final Terraform convergence:

```bash
terraform plan -var-file=lab.tfvars
```

Expected result: `No changes`.

## Completion criteria

The reproduced environment is complete when:

- Terraform manages only the intended four VMs and reports no drift;
- the source template remains external and unchanged;
- the Ansible private key exists only on `ansible-controller`;
- the control plane and every configured worker are `Ready`;
- DNS, Service ClusterIP, and cross-worker Pod connectivity tests pass;
- Git contains no secret, private key, state file, or local variable file.
