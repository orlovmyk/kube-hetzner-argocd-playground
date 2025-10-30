---
apiVersion: v1
kind: Namespace
metadata:
  name: dex

---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: dex
  namespace: dex
spec:
  chart: dex
  version: 0.19.1
  repo: https://charts.dexidp.io
  targetNamespace: dex
  bootstrap: true
  valuesContent: |-
    configSecret:
      create: false
      name: "dex-config" # created by gitea.tf

    ingress:
      enabled: true
      className: nginx
      annotations:
        cert-manager.io/cluster-issuer: "letsencrypt-prod"

      hosts:
        - host: dex.${global_domain}
          paths:
            - path: /
              pathType: ImplementationSpecific

      tls:
        - secretName: dex-ingress-tls
          hosts:
            - dex.${global_domain}
