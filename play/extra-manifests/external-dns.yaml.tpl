---
apiVersion: v1
kind: Namespace
metadata:
  name: external-dns

---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: external-dns
  namespace: external-dns
spec:
  chart: external-dns
  version: 1.15.0
  repo: https://kubernetes-sigs.github.io/external-dns/
  targetNamespace: external-dns
  bootstrap: true
  valuesContent: |-
    # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/cloudflare.md#using-helm
    policy: sync
    provider:
      name: cloudflare
    env:
      - name: CF_API_TOKEN
        value: ${cloudflare_api_token}
