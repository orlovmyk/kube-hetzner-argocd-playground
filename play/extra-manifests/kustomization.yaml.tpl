apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# https://docs.k3s.io/helm/
# manages HelmChart resources

resources:
  # crds
  - https://github.com/cert-manager/cert-manager/releases/download/v1.19.1/cert-manager.crds.yaml
  # helm charts
  - external-dns.yaml
  - cert-manager.yaml
  - dex.yaml
  - argocd.yaml
  - gitea.yaml
  - reloader.yaml
