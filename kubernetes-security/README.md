# Заметки по выполнению домашней работы по теме "Безопасность и управление доступом"


## Создаем кластер с 1 воркером и 1 мастером

~~~ yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
  - role: control-plane
  - role: worker

~~~

## task01

* Создать Service Account bob

~~~ yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
 name: bob

~~~
* Создать Service Account dave без доступа к кластеру
~~~ yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
 name: dave
~~~

* дать bob роль admin в рамках всего кластера
~~~ yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-serv
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: bob
  namespace: default

~~~

## task02
* Создать Namespace prometheus
~~~ yaml
apiVersion: v1
kind: Namespace
metadata:
  name:  prometheus
~~~

Создать Service Account carol в  Namespace prometheus
~~~ yaml
---

apiVersion: v1
kind: ServiceAccount
metadata:
  name:  carol
  namespace: prometheus
~~~

* Дать всем Service Account в Namespace prometheus возможность делать get, list, watch в отношении Pods всего кластера
~~~ yaml
---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-role
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
~~~

~~~ yaml
---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus-role
subjects:
- kind: Group
  name: system:serviceaccounts:prometheus
  apiGroup: rbac.authorization.k8s.io
~~~


## task03

* Создать Namespace dev

~~~ yaml
apiVersion: v1
kind: Namespace
metadata:
  name:  dev
~~~

* Создать Service Account jane в Namespace dev

~~~ yaml
---

apiVersion: v1
kind: ServiceAccount
metadata:
  name:  jane
  namespace: dev
~~~


* Дать jane роль admin в рамках Namespace dev

~~~ yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jane-admin
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: jane
  namespace: dev
~~~

* Создать Service Account ken в Namespace dev

~~~ yaml
---

apiVersion: v1
kind: ServiceAccount
metadata:
  name:  ken
  namespace: dev
~~~

* Дать ken роль view в рамках Namespace dev

~~~ yaml
--- 
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ken-view
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: ken
  namespace: dev