---
apiVersion: v1
kind: Namespace
metadata:
  name: gitea

---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: gitea
  namespace: gitea
spec:
  chart: gitea
  version: 12.4.0
  repo: https://dl.gitea.io/charts/
  targetNamespace: gitea
  bootstrap: true
  valuesContent: |-
    # https://artifacthub.io/packages/helm/gitea/gitea/2.2.0

    ingress:
      enabled: true
      className: nginx
      annotations:
        cert-manager.io/cluster-issuer: "letsencrypt-prod"

      hosts:
        - host: "git.${global_domain}"
          paths:
            - path: /
              pathType: Prefix
      tls:
        - secretName: gitea-tls
          hosts:
            - "git.${global_domain}"

    gitea:
      admin:
        username: ${gitea_admin_username}
        email: ${gitea_admin_email}
        password: ${gitea_admin_password}
        passwordMode: keepUpdated

      config:
        server:
          SSH_PORT: 2222

    redis-cluster:
      enabled: false

    redis:
      enabled: true
      architecture: standalone
      global:
        redis:
          password: changeme
      master:
        count: 1

    postgresql-ha:
      enabled: false

    postgresql:
      enabled: true
      global:
        postgresql:
          auth:
            password: gitea
            database: gitea
            username: gitea
          service:
            ports:
              postgresql: 5432

      primary:
        persistence:
          size: 5Gi

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/whitelist-source-range: 0.0.0.0/0,::/0 
  name: argocd-server-whitelist-all
  namespace: argocd
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.${global_domain}
    http:
      paths:
      - backend:
          service:
            name: argocd-server
            port:
              number: 80
        path: /api/webhook
        pathType: Prefix
  tls:
  - hosts:
    - argocd.${global_domain}
    secretName: argocd-server-tls

