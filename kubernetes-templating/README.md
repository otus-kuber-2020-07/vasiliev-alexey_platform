# Заметки по выполнению домашней работы по теме "Шаблонизация манифестов. Helm и его аналоги (Jsonnet, Kustomize)"

## Создаем инфраструктуру в GKE

~~~ sh
export TF_VAR_project_name=XXX
cd infra && terraform apply -auto-approve
~~~

## установка nginx-ingress   cert-manager  chartmuseum harbor

Устанавливаем  внешний IP, полученный в GKE  из [terraform output](../infra/outputs.tf) (loadBalancerIP)

~~~ sh
export TF_VAR_project_name=XXX
cd tf-provisioner && terraform apply -auto-approve
~~~

Все задеплоится само через  terraform-provider-helm  само и будет доступно

~~~ sh
export INGRESS_IP=$(kubectl get svc nginx-nginx-ingress-controller -n nginx-ingress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl https://chartmuseum.$INGRESS_IP.nip.io
curl https://harbor.$INGRESS_IP.nip.io
~~~

### Задание со ⭐ Научитесь работать с chartmuseum

 chartmuseum - по сути простой веб сервис и [инструкция](https://chartmuseum.com/docs/#uploading-a-chart-package)  изложена на офицальном сайте.

### Используем helmfile | Задание со ⭐

 Почитал про helmfile - понял что, это все я проделал в файле [terraform](tf-provisioner/main.tf) - все тот же DSL, но на YAML, а у меня на HCL

## Создаем свой helm chart

 Создали по шаблону свой чарт

~~~ sh
helm create kubernetes-templating/frontend39/72

~~~

И на основе заготовки создали свой чарт для фронта.

### Создаем свой helm chart | Задание со ⭐

В [Chart.yaml](hipster-shop/Chart.yaml) - добавлен установка Redis из комьюнити чарта

## Kubecfg

* Вынесли еще 2 сервиса paymentservice и shippingservice в отдельные сервисы
* Загрузили библиотеку для генерации манифестов [libsonnet](kubecfg/kube.libsonnet)  и немного ее допилили.
* создали шаблон генерации манифестов [services.jsonnet](kubecfg/services.jsonnet)
* сгенерировали манифесты и применили

~~~ sh
kubecfg update services.jsonnet --namespace hipster-shop
~~~

## Kustomize

* выпилили сервис currencyservice
* создали структуру каталогов для base и overrides
* используя утилиту kustomize добавили ресурсы в kustomization.yaml

~~~ sh
kustomize edit add resource  ./currencyservice-service.yaml
~~~

* переопределили часть атрибутов из [списка возможных](https://github.com/kubernetes-sigs/kustomize)
* применили манифесты для окружения  prod
