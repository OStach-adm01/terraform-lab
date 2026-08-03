# Roadmap

Cel: zbudować i udokumentować homelab pokazujący podstawowe umiejętności Junior DevOps / SysOps / SysAdmin.

## 1. Terraform + Proxmox

- [x] Przygotować Ubuntu Cloud-Init template.
- [x] Skonfigurować provider i przechowywać sekrety poza Git.
- [x] Zainicjalizować Terraform i wersjonować lock file.
- [ ] Utworzyć `ansible-controller` z kluczem SSH i statycznym IP.
- [ ] Zbudować moduł VM i utworzyć węzły Kubernetes.
- [ ] Dodać outputy IP oraz dokumentację infrastruktury.

## 2. Ansible

- [ ] Utworzyć inventory i połączenie SSH.
- [ ] Stworzyć rolę `common` (aktualizacje, pakiety, użytkownik, podstawowy hardening).
- [ ] Stworzyć role przygotowujące węzły Kubernetes.
- [ ] Zapewnić idempotencję i uruchomić `ansible-lint`.

## 3. Kontenery

- [ ] Zbudować prostą aplikację demo w Dockerze.
- [ ] Opisać Dockerfile, tagowanie obrazów i podstawy bezpieczeństwa obrazu.
- [ ] Udostępnić obraz lokalnie lub w rejestrze kontenerów.

## 4. Kubernetes

- [ ] Utworzyć control plane i workery przez Terraform.
- [ ] Skonfigurować klaster przez Ansible i kubeadm.
- [ ] Zainstalować CNI, metrics-server i ingress controller.
- [ ] Wdrożyć aplikację: Deployment, Service, Ingress, ConfigMap, Secret i HPA.

## 5. Jakość i portfolio

- [ ] Dodać testy: `terraform fmt`/`validate`, `tflint`, `ansible-lint` i `yamllint`.
- [ ] Uzupełnić README o diagram, instrukcję uruchomienia i troubleshooting.
- [ ] Udokumentować decyzje, ograniczenia i sposób bezpiecznego niszczenia labu.

## Plan adresacji

| Adres | Nazwa | Rola |
| --- | --- | --- |
| `192.168.0.220/24` | `ansible-controller` | Kontroler Ansible |
| `192.168.0.221/24` | `k8s-cp-01` | Kubernetes control plane |
| `192.168.0.222/24` | `k8s-worker-01` | Kubernetes worker |
| `192.168.0.223/24` | `k8s-worker-02` | Kubernetes worker |

Brama i DNS: `192.168.0.1`. Przed utworzeniem VM sprawdzamy dostępność wybranego adresu; docelowo adresy powinny zostać wyłączone z puli DHCP lub zarezerwowane na routerze.
