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

## Canary deployments с Flagger и IstioFlagger и Istio



* Установку Istio  - пропустили, реализовывается через GKE

~~~ yaml
 addons_config {
    istio_config {
      disabled = false
      auth     = "AUTH_NONE"
    }
  }
~~~

* Автоматизирована установка Flagger  с помощью [Terraform](flagger/main.tf)  
  Для установки CRD   применен новый провайдер для [k8s-terraform](https://github.com/hashicorp/terraform-provider-kubernetes-alpha). Для корректной работы требуется k8s версии не ниже 1.17 - поднял версию в инфраструктурном проекте
* Дали доступ для микросервиса  frontend
* Создали манифест для Canary-развертывания
* Определите причину неуспешности релиза - причина в  том, что flagger не получает метрик от Prometheus сервера.
* Добейтесь успешного выполнения релиза - не получилось, (то ли  тупой, то ли лыжи не едут. Почитал исходники, инциденты на GH  - не разобрался)

~~~ sh
kubectl get canaries --all-namespaces                                                                                                                                                                                                    21:00:01 07/10/20
NAMESPACE            NAME       STATUS   WEIGHT   LASTTRANSITIONTIME
microservices-demo   frontend   Failed   0        2020-10-07T17:29:23Z
~~~

~~~ json
"level":"info","ts":"2020-10-07T17:28:23.014Z","caller":"controller/events.go:28","msg":"Halt advancement no values found for istio metric request-success-rate probably frontend.microservices-demo is not receiving traffic: running query failed: no values found","canary":"frontend.microservices-demo"}

~~~

## Статьи и материалы

https://stanislas.blog/2018/09/build-push-docker-images-gitlab-ci/
[Автоматические canary деплои с Flagger и Istio](https://habr.com/ru/company/southbridge/blog/444808/)
[Установка Flagger на GKE](https://docs.flagger.app/install/flagger-install-on-google-cloud)