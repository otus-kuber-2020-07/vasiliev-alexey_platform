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


~~~ sh
kubectl get canary -n microservices-demo                                                     18:59:11 12/10/20
NAME       STATUS      WEIGHT   LASTTRANSITIONTIME
frontend   Succeeded   0        2020-10-12T15:58:55Z
~~~

~~~ sh
Status:
  Canary Weight:  0
  Conditions:
    Last Transition Time:  2020-10-12T15:58:55Z
    Last Update Time:      2020-10-12T15:58:55Z
    Message:               Canary analysis completed successfully, promotion finished.
    Reason:                Succeeded
    Status:                True
    Type:                  Promoted
  Failed Checks:           0
  Iterations:              0
  Last Applied Spec:       c8f748774
  Last Promoted Spec:      c8f748774
  Last Transition Time:    2020-10-12T15:58:55Z
  Phase:                   Succeeded
  Tracked Configs:
Events:
  Type    Reason  Age                    From     Message
  ----    ------  ----                   ----     -------
  Normal  Synced  4m46s (x2 over 3h12m)  flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal  Synced  4m16s (x2 over 3h12m)  flagger  Starting canary analysis for frontend.microservices-demo
  Normal  Synced  4m16s (x2 over 3h12m)  flagger  Advance frontend.microservices-demo canary weight 5
  Normal  Synced  3m46s                  flagger  Advance frontend.microservices-demo canary weight 10
  Normal  Synced  3m16s                  flagger  Advance frontend.microservices-demo canary weight 15
  Normal  Synced  2m46s                  flagger  Advance frontend.microservices-demo canary weight 20
  Normal  Synced  2m16s                  flagger  Advance frontend.microservices-demo canary weight 25
  Normal  Synced  106s                   flagger  Advance frontend.microservices-demo canary weight 30
  Normal  Synced  76s                    flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal  Synced  16s (x2 over 46s)      flagger  (combined from similar events): Promotion completed! Scaling down frontend.microservices-demo

~~~

## Статьи и материалы

https://stanislas.blog/2018/09/build-push-docker-images-gitlab-ci/  
[Автоматические canary деплои с Flagger и Istio](https://habr.com/ru/company/southbridge/blog/444808/)  
[Установка Flagger на GKE](https://docs.flagger.app/install/flagger-install-on-google-cloud)  
[Automated canary deployments with Flagger and Istio](https://medium.com/google-cloud/automated-canary-deployments-with-flagger-and-istio-ac747827f9d1)