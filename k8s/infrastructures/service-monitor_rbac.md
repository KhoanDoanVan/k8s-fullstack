# 🧠 Prometheus RBAC Configuration

This README explains the purpose and meaning of the Kubernetes YAML
configuration for **Prometheus RBAC (Role-Based Access Control)**.

------------------------------------------------------------------------

## 1️⃣ ServiceAccount

The **ServiceAccount** defines an identity under which Prometheus Pods
will run.\
This identity is used to authenticate with the Kubernetes API server
when Prometheus fetches cluster data.

``` yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: infrastructures
```

-   **Name:** prometheus\
-   **Namespace:** infrastructures\
-   **Purpose:** Allows Prometheus to authenticate securely with
    Kubernetes API using a token associated with this ServiceAccount.

------------------------------------------------------------------------

## 2️⃣ ClusterRole

The **ClusterRole** defines the set of permissions that Prometheus will
have to read Kubernetes objects across the cluster.

``` yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroup: [""]
  resources: [nodes, services, endpoints, pods]
  verbs: [get, list, watch]
- apiGroup: [""]
  resources: [configmaps]
  verbs: [get]
```

### 🔍 Permissions Explanation

Prometheus can: - `get`, `list`, and `watch` these core resources: -
**nodes:** retrieve metrics from Kubernetes nodes. - **services:**
discover running services. - **endpoints:** locate actual service
endpoints (pods). - **pods:** scrape metrics directly from pod
endpoints. - `get` **configmaps** (often used for configuration
discovery).

------------------------------------------------------------------------

## 3️⃣ ClusterRoleBinding

The **ClusterRoleBinding** links the ClusterRole to the ServiceAccount,
granting it the defined permissions.

``` yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: infrastructures
```

This ensures that the ServiceAccount `prometheus` in the
`infrastructures` namespace can use the permissions defined in the
`ClusterRole prometheus`.

------------------------------------------------------------------------

## 🧾 Summary Table

  ------------------------------------------------------------------------
  Component              Kind                             Purpose
  ---------------------- -------------------------------- ----------------
  prometheus             ServiceAccount                   Identity for
                                                          Prometheus Pods
                                                          to access the
                                                          Kubernetes API

  prometheus             ClusterRole                      Defines what
                                                          resources and
                                                          actions
                                                          Prometheus can
                                                          perform

  prometheus             ClusterRoleBinding               Grants the
                                                          ClusterRole
                                                          permissions to
                                                          the
                                                          ServiceAccount
  ------------------------------------------------------------------------

------------------------------------------------------------------------

## 💡 Why Prometheus Needs RBAC

Prometheus uses these permissions for Kubernetes **service discovery**
to automatically detect and scrape targets like node exporters, pods,
and kubelets.\
Without these permissions, Prometheus cannot dynamically monitor the
cluster state.
