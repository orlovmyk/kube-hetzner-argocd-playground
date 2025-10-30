terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.43.0"
    }
    gitea = {
      source  = "go-gitea/gitea"
      version = "0.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
}
