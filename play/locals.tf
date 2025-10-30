locals {
  cluster_name  = basename(abspath(path.module)) # pick up folder name
  global_domain = "${local.cluster_name}.${var.global_domain}"

  ###################

  # gitea
  gitea_admin_username = "gitea_admin"
  gitea_admin_password = random_password.gitea_admin_password.result
  gitea_admin_email    = "gitea_admin@${local.global_domain}"

  # TODO: add migration
  # gitea_template_repo  = "https://github.com/orlov-m/gitops-template.git"

  dex_clients = ["argocd"]

  gitops_https_url = "https://git.${local.global_domain}/${local.gitea_admin_username}/gitops.git"
}

# resources
resource "random_password" "gitea_admin_password" {
  length  = 32
  special = false
}

resource "tls_private_key" "gitea_ssh_key" {
  algorithm = "ED25519"
}

resource "tls_private_key" "hetzner_ssh_key" {
  algorithm = "ED25519"
}

resource "random_password" "dex_client_secrets" {
  for_each = toset(local.dex_clients)
  length   = 32
  special  = false
}

resource "local_sensitive_file" "credentials" {
  content = yamlencode({
    gitea_url            = "https://git.${local.global_domain}"
    gitea_admin_username = local.gitea_admin_username
    gitea_admin_password = random_password.gitea_admin_password.result
    gitea_admin_email    = local.gitea_admin_email

    argocd_url = "https://argocd.${local.global_domain}"

    dex_client_secrets = {
      for k, v in random_password.dex_client_secrets : k => v.result
    }
  })
  filename = "${local.cluster_name}_credentials.yaml"
}

resource "local_sensitive_file" "gitea_ssh_key" {
  content  = tls_private_key.gitea_ssh_key.private_key_pem
  filename = "${local.cluster_name}_gitea.pem"
}

resource "local_sensitive_file" "hetzner_ssh_key" {
  content  = tls_private_key.hetzner_ssh_key.private_key_pem
  filename = "${local.cluster_name}_hetzner.pem"
}

# outputs
output "gitea_admin_username" {
  value     = local.gitea_admin_username
  sensitive = false
}

output "gitea_admin_password" {
  value     = local.gitea_admin_password
  sensitive = true
}

output "dex_client_secrets" {
  value     = { for k, v in random_password.dex_client_secrets : k => v.result }
  sensitive = true
}

output "kubeconfig" {
  value     = module.kube-hetzner.kubeconfig
  sensitive = true
}
