provider "gitea" {
  base_url = "https://git.${local.global_domain}"

  username = local.gitea_admin_username
  password = local.gitea_admin_password
}

provider "kubernetes" {
  config_path = "${local.cluster_name}_kubeconfig.yaml"
}

resource "gitea_repository" "gitops" {
  username = local.gitea_admin_username
  name     = "gitops"
  private  = true
  mirror   = false

  # TODO
  # migration_clone_address      = local.gitea_template_repo
  # migration_service            = "gogs"
  # migration_service_auth_token = "not-your-business"

  depends_on = [module.kube-hetzner]
}

resource "gitea_public_key" "gitops" {
  title    = "gitops"
  key      = tls_private_key.gitea_ssh_key.public_key_openssh
  username = local.gitea_admin_username

  depends_on = [module.kube-hetzner]
}

resource "gitea_oauth2_app" "dex" {
  name = "dex"
  redirect_uris = [
    "https://dex.${local.global_domain}/callback",
  ]
  confidential_client = true

  depends_on = [module.kube-hetzner]
}

resource "gitea_repository_webhook" "gitops" {
  active        = true
  name          = gitea_repository.gitops.name
  branch_filter = "*"
  username      = local.gitea_admin_username
  url           = "https://argocd.${local.global_domain}/api/webhook"
  content_type  = "json"
  events        = ["push"]
  type          = "gitea"

  depends_on = [module.kube-hetzner]
}

resource "kubernetes_secret" "dex" {
  metadata {
    name      = "dex-config"
    namespace = "dex"
  }

  data = {
    "config.yaml" = <<EOT
issuer: https://dex.${local.global_domain}

storage:
  type: kubernetes
  config:
    inCluster: true

connectors:
  - type: gitea
    id: gitea
    name: Gitea
    config:
      clientID: ${gitea_oauth2_app.dex.client_id}
      clientSecret: ${gitea_oauth2_app.dex.client_secret}
      baseURL: https://git.${local.global_domain}
      redirectURI: https://dex.${local.global_domain}/callback

# to add other connectors add local.dex_clients and iterate over them
staticClients:
  - id: argocd
    name: ArgoCD
    secret: ${random_password.dex_client_secrets["argocd"].result}
    redirectURIs:
      - https://argocd.${local.global_domain}/auth/callback
EOT
  }

  depends_on = [module.kube-hetzner]
}

