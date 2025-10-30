variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

module "kube-hetzner" {
  network_ipv4_cidr = var.network_ipv4_cidr # must be unique across all clusters
  cluster_name      = local.cluster_name

  providers = {
    hcloud = hcloud
  }
  hcloud_token = var.hcloud_token

  source  = "kube-hetzner/kube-hetzner/hcloud"
  version = "2.18.4"

  ssh_public_key  = tls_private_key.hetzner_ssh_key.public_key_openssh
  ssh_private_key = tls_private_key.hetzner_ssh_key.private_key_openssh

  network_region = "eu-central"

  enable_klipper_metal_lb = "true"

  control_plane_nodepools = [
    {
      name        = "control-plane-fsn1",
      server_type = "cx23",
      location    = "fsn1",
      labels      = ["k3s_upgrade=false"],
      taints      = [],
      count       = 1
    }
  ]

  agent_nodepools = [
    {
      name        = "agent-fsn1",
      server_type = "cx33",
      location    = "fsn1",
      labels = [
        "node.kubernetes.io/server-usage=storage",
        "k3s_upgrade=false"
      ],
      taints = [],
      count  = 1
    }
  ]

  ### The following values are entirely optional (and can be removed from this if unused) ###

  ### automatic upgrades
  automatically_upgrade_k3s      = false
  system_upgrade_use_drain       = false
  system_upgrade_enable_eviction = false
  automatically_upgrade_os       = false

  ### cni
  cni_plugin = "flannel"

  ### naming
  use_cluster_name_in_node_name = true

  extra_firewall_rules = [
    {
      description     = "Allow ArgoCD access to resources via SSH"
      direction       = "in"
      protocol        = "tcp"
      port            = "2222"
      source_ips      = ["0.0.0.0/0", "::/0"]
      destination_ips = []
    },
    {
      description     = "Allow ALL"
      direction       = "out"
      protocol        = "tcp"
      port            = "1024-65535"
      source_ips      = []
      destination_ips = ["0.0.0.0/0", "::/0"]
    },
    {
      description     = "Allow ALL"
      direction       = "out"
      protocol        = "udp"
      port            = "1024-65535"
      source_ips      = []
      destination_ips = ["0.0.0.0/0", "::/0"]
    }
  ]

  initial_k3s_channel = "stable"

  ingress_controller = "nginx"

  enable_cert_manager = false
  disable_hetzner_csi = false
  hetzner_csi_version = "v2.11.0"

  create_kubeconfig = true

  # extra HelmChart resources in extra-manifests folder
  extra_kustomize_parameters = merge({
    "global_domain"        = local.global_domain
    "gitea_admin_username" = local.gitea_admin_username
    "gitea_admin_password" = local.gitea_admin_password
    "gitea_admin_email"    = local.gitea_admin_email
    "gitops_https_url"     = local.gitops_https_url
    "gitops_ssh_key"       = indent(12, tls_private_key.gitea_ssh_key.private_key_pem)
    "cloudflare_api_token" = var.cloudflare_api_token
    }, {
    for k, v in random_password.dex_client_secrets : "dex_client_secret_${k}" => v.result
  })

  # https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/blob/master/locals.tf#L550
  nginx_values = <<EOT
controller:
  watchIngressWithoutClass: "true"
  kind: "Deployment"
  replicaCount: 1
  config:
    "use-forwarded-headers": "true"
    "compute-full-forwarded-for": "true"
    "use-proxy-protocol": "false"
  service:
    ports:
      http: 80
      https: 443
      ssh: 2222
    targetPorts:
      http: http
      https: https
      ssh: ssh
tcp:
  "2222": "gitea/gitea-ssh:22"
EOT

  microos_x86_snapshot_id = var.microos_x86_snapshot_id
  microos_arm_snapshot_id = var.microos_arm_snapshot_id
}

