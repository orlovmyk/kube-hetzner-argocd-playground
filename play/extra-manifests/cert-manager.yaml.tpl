---
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager

---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  chart: cert-manager
  version: 1.19.1
  repo: https://charts.jetstack.io
  targetNamespace: cert-manager
  bootstrap: true
  valuesContent: |-
    crds:
      enabled: false
      keep: true

---
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  token: "${cloudflare_api_token}"

---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-stg
  namespace: cert-manager
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-stg
    solvers:
      - dns01:
          cloudflare:
            email: "${gitea_admin_email}"
            apiTokenSecretRef:
              name: cloudflare-api-token
              key: token

---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - dns01:
          cloudflare:
            email: "${gitea_admin_email}"
            apiTokenSecretRef:
              name: cloudflare-api-token
              key: token
