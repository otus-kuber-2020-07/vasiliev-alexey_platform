# GitOps и инструменты поставки 


## Создали [проект в GitLab](https://gitlab.com/vasiliev-alexey/microservices-demo) и залили в него исходные коды 

* создали чарты для развертывания
* пришлось немного подрисовать в процессе - на фронте удалил деплоймент мониторинга
* [автоматизировали создание](https://gitlab.com/vasiliev-alexey/gke-tf-cluster) кластера k8s через Terraform
* Создали [Makefile](https://gitlab.com/vasiliev-alexey/microservices-demo/-/blob/master/src/Makefile) для ручной сборки и пуша образов микросервисов
* Запилили [пайплайн](https://gitlab.com/vasiliev-alexey/microservices-demo/-/blob/master/.gitlab-ci.yml) сборки микросервисов



## GitOps

* автоматизировано [развертывание fluxcd и fluxcd/helm-operator через Terraform](gitops/main.tf)
* Созданы [манифесты для развертывания HelmRelease](https://gitlab.com/vasiliev-alexey/microservices-demo/-/tree/master/deploy/releases) для всех микросервисов
Проверка измнений осуществляется через обсчет Хеша в конфигурационных файлах, по ключевым полям

~~~ sh
ts=2020-10-02T19:23:17.650372165Z caller=daemon.go:701 component=daemon event="Sync: 1190d12, microservices-demo:helmrelease/frontend-hipster" logupstream=false

~~~

~~~ sh
  Last Attempted Revision:  47bc110a79f3a2b42d55446c2a4209ee3379686a
  Observed Generation:      2
  Phase:                    Succeeded
  Release Name:             frontend
  Release Status:           deployed
  Revision:                 47bc110a79f3a2b42d55446c2a4209ee3379686a
~~~

## Canary deployments сFlagger и IstioFlagger и Istio


## Статьи и материалы

https://stanislas.blog/2018/09/build-push-docker-images-gitlab-ci/