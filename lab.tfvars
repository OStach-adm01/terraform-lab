vms = {
  ansible_controller = {
    vm_id        = 310
    cpu_cores    = 2
    memory_mb    = 2048
    ipv4_address = "192.168.0.220/24"
    tags         = ["terraform", "ansible", "linux"]
  }

  k8s_cp_01 = {
    vm_id           = 311
    cpu_cores       = 2
    memory_mb       = 2048
    ipv4_address    = "192.168.0.221/24"
    tags            = ["terraform", "ansible", "kubernetes", "control-plane"]
    ansible_managed = true
  }

  k8s_worker_01 = {
    vm_id           = 312
    cpu_cores       = 1
    memory_mb       = 2048
    ipv4_address    = "192.168.0.222/24"
    tags            = ["terraform", "ansible", "kubernetes", "worker"]
    ansible_managed = true
  }

  k8s_worker_02 = {
    vm_id           = 313
    cpu_cores       = 1
    memory_mb       = 2048
    ipv4_address    = "192.168.0.223/24"
    tags            = ["terraform", "ansible", "kubernetes", "worker"]
    ansible_managed = true
  }
}
