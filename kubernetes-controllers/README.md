# Заметки по выполнению домашней работы по теме "Механика запуска и взаимодействия контейнеров в Kubernetes"
[![Build Status](https://travis-ci.com/otus-kuber-2020-07/vasiliev-alexey_platform.svg?branch=kubernetes-controllers)](https://travis-ci.com/otus-kuber-2020-07/vasiliev-alexey_platform)
1. Создали kind кластер с 6 нодами
2. Создали ReplicaSet  для сервиса frontend и paymentservice.
4. Научились масштабировать конфигурацию сервисов

~~~
kubectl scale replicaset frontend --replicas=3
~~~
научились задавать начальное масштабирование конфигурации
~~~yaml
spec:
  replicas: 3
~~~

Обновление конфигурации ReplicaSet не приводит к обновлению pod-ов, так как в  ReplicaSet не  проверяет на соответствие pod-а  шаблону, он следит за  количеством запущенных pod-ов.

5. Научились создавать Deployment
6. Научились откатывать неудавшиеся деплойменты
~~~
kubectl rollout undo deployment paymentservice --to-revision=1 
~~~

7. Создали Deployment для [blue-green](paymentservice-deployment_bg.yaml) и [ReverseRollingUpdate](paymentservice-deployment_reverse.yaml)

8. Сконфигурировали Deployment для использования  readinessProbe
~~~yaml
readinessProbe:
initialDelaySeconds: 10
httpGet:
    path: "/_healthz"
    port: 8080
    httpHeaders:
    - name: "Cookie"
    value: "shop_session-id=x-readiness-probe"
~~~

9. Изучили конфигурацию DaemonSet. Создали свой [для развертывания](node-exporter-daemonset.yaml) NodeExporter
Скофигурировали его, чтобы он равертывался на всех нодах
~~~yaml
tolerations:
# this toleration is to have the daemonset runnable on master nodes
# remove it if your masters can't run pods
    - key: node-role.kubernetes.io/master
    effect: NoSchedule
~~~