---
apiVersion: v1
kind: Namespace
metadata:
  name: reloader

---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: reloader
  namespace: reloader
spec:
  chart: reloader
  version: 2.2.3
  repo: https://stakater.github.io/stakater-charts
  targetNamespace: reloader
  bootstrap: true
  valuesContent: |-
    reloader:
      autoReloadAll: true