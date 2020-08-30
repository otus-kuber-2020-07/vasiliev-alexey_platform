# Заметки по выполнению домашней работы по теме "Безопасность и управление доступом"


## Создаем инфраструктуру в GKE

~~~ sh
cd infra && terraform apply -auto-approve
~~~

## установка nginx-ingress через Helm chart

~~~ sh
helm upgrade --install nginx-ingress stable/nginx-ingress --wait   --namespace=nginx-ingress   --version=1.41.3 --create-namespace
~~~

## установка cert-manager
* добавим репозиторий
~~~ sh
helm repo add jetstack https://charts.jetstack.io
~~~

* Создадим CRD  для установки
  
~~~ sh
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.16.1/cert-manager.crds.yaml 
~~~

* Установим cert-manager -в инструкцию надо создать NS или добавить 
~~~ sh
helm upgrade --install cert-manager jetstack/cert-manager --wait   --namespace=cert-manager   --version=0.16.1  --create-namespace
~~~

* Создадим [ClusterIssuer](cert-manager/clusterissuer.yaml) для выпуска сертификатов
  
~~~ yaml
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: nomail@mail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers: 
    - http01:
        ingress:
          class: nginx
~~~


## Устновка chartmuseum
Создадим файл с [параметрами установки](chartmuseum/values.yaml)

Задеплоим чарт

~~~ sh
helm upgrade --install chartmuseum stable/chartmuseum --wait    --namespace=chartmuseum    --version=2.13.2   -f chartmuseum/values.yaml  --create-namespace
~~~

## harbor