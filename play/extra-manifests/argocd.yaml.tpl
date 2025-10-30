---
apiVersion: v1
kind: Namespace
metadata:
  name: argocd

---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: argocd
  namespace: argocd
spec:
  chart: argo-cd
  version: 9.0.5
  repo: https://argoproj.github.io/argo-helm
  bootstrap: false
  targetNamespace: argocd
  valuesContent: |-
    global:
      domain: "argocd.${global_domain}"
    crds:
      install: true
      keep: true
    configs:
      cm:
        create: true
        exec.enabled: "true"
        cluster.inClusterEnabled: "true"
        oidc.config: |
          name: dex
          issuer: "https://dex.${global_domain}"
          clientID: "argocd"
          clientSecret: ${dex_client_secret_argocd}
          requestedScopes: ["openid", "profile", "email", "groups"]
      rbac:
        create: true
        policy.csv: |
          g, ${gitea_admin_email}, role:admin
        scopes: "[groups, openid, profile, email]"

      params:
        server.insecure: true
        application.namespaces: "argocd"
      repositories:
        docker-io:
          name: registry-1.docker.io
          url: registry-1.docker.io
          type: helm
          username: docker
          password: ""
          enableOCI: "true"
        gitea-https:
          name: gitea-https
          url: ${gitops_https_url}
          type: git
          username: ${gitea_admin_username}
          password: ${gitea_admin_password}

    server:
      ingress:
        enabled: true
        hostname: "argocd.${global_domain}"
        ingressClassName: nginx
        annotations:
          cert-manager.io/cluster-issuer: letsencrypt-prod
          nginx.org/websocket-services: "argocd-server"
        tls:
          - hosts:
              - "argocd.${global_domain}"
    dex:
      enabled: false
    applicationSet:
      enabled: true

---
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: appproject-default
  namespace: "argocd"
spec:
  sourceNamespaces: 
    - "argocd"
  destinations:
    - namespace: '*'
      server: 'https://kubernetes.default.svc'
  sourceRepos:
    - '*'
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'

---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: applicationset-default
  namespace: "argocd"
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - git:
        repoURL: "${gitops_https_url}"
        revision: HEAD
        directories:
          - path: '*'
  template:
    metadata:
      name: '{{.path.basename}}'
      annotations:
        argocd.argoproj.io/compare-options: ServerSideDiff=true,IncludeMutationWebhook=true
    spec:
      project: "appproject-default"
      source:
        repoURL: "${gitops_https_url}"
        targetRevision: HEAD
        path: '{{.path.path}}'
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: '{{.path.basename}}'
      syncPolicy:
        automated:
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
          - ApplyOutOfSyncOnly=true
