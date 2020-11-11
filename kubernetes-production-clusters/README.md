# Создание и обновление кластера при помощи kubeadm

## Цель: Научимся пользоваться kubeadm для создания и обновления кластеров

---

## Решение

### kubeadm

1. Создаем и "запекаем" [базовый образ](./packer/node.pkr.hcl) для нод кластера с помощью Packer.
2. С помощью [Terraform](tf_k8s_install/main.tf) поднимаем машины для  создаваемого кластера 
3. и провиженим туда команды для создания кластера. (на локальной машине должен быть установлен jq -  используется для получения токена из мастер ноды)

Результат

``` sh
appuser@k8s-master-0:~$ kubectl get nodes
NAME           STATUS   ROLES    AGE     VERSION
k8s-master-0   Ready    master   4m45s   v1.17.4
k8s-worker-0   Ready    <none>   23s     v1.17.4
k8s-worker-1   Ready    <none>   23s     v1.17.4
k8s-worker-2   Ready    <none>   23s     v1.17.4
```

4. Обновляем k8s

На основе утилиты terraform  написан  [сценарий обновления кластера](tf_k8s_upgrade/main.tf)  k8s созданного выше.
По хорошему надо было бы вынести  логику обновления в модуль и использовать его параметризируя номер worker-ноды из счетчика цикла   - но,  это не сделал - пока обойдемся локальной переменной, и просто прокатим  манифест несколько раз.
Обновление мастера идемпотентно - проблем не вызывает

``` sh
null_resource.k8s-master-0-fin (remote-exec): NAME           STATUS   ROLES    AGE    VERSION
null_resource.k8s-master-0-fin (remote-exec): k8s-master-0   Ready    master   3h5m   v1.18.0
null_resource.k8s-master-0-fin (remote-exec): k8s-worker-0   Ready    <none>   3h4m   v1.18.0
null_resource.k8s-master-0-fin (remote-exec): k8s-worker-1   Ready    <none>   3h4m   v1.18.0
null_resource.k8s-master-0-fin (remote-exec): k8s-worker-2   Ready    <none>   3h4m   v1.18.0
null_resource.k8s-master-0-fin (remote-exec): **************************************************************************
```

### kubesparay

1. Создаем машинки в  GCP через [terraform](tf_vms/main.tf)

2. Назначаем созданные IP в инвентори файл 
``` sh
app_external_ip = [
  "130.211.61.117",
  "34.76.55.199",
  "35.187.33.116",
  "35.190.196.115",
]
```

3. прокатываем плейбук

``` sh
ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root \
--user=appuser --key-file=~/.ssh/appuser cluster.yml
```
 wait ... wait ... wait ... bingo

``` sh
appuser@master1:~$ kubectl get nodes
NAME      STATUS   ROLES    AGE     VERSION
master1   Ready    master   9m22s   v1.19.3
master2   Ready    master   8m57s   v1.19.3
master3   Ready    master   8m58s   v1.19.3
worker1   Ready    <none>   7m32s   v1.19.3
```


⭐ Лимитов GCP  по IP не хватило  - а прятать ноды за NAT и ходить через бастион - ну так себе  для ДЗ.
Сократил 1 worker-node.