# Диагностика и отладка кластера и приложений в нем

## Проведение диагностики состояния кластера, знакомство с инструментами для диагностики. Цель: В данном дз студенты научатся пользоваться инструментами для отладки кластера kubernetes.  

Такими как:  
* strace
* kubectl-debug
* iptables-tailer

---
## Решение

### kubectl-debug
1. Устанавливаем kubectl-debug версии v0.2.0-rc

    Чинить ничего не пришлось - в версии v0.1.1 привилегии добавлены

2. Запустили команду на подключение к поду

``` sh
kubectl debug storage_pod
```

Запускаем strace - подключаемся к nginx - worker

``` sh
bash-5.0# strace  -p 28
strace: Process 28 attached
epoll_wait(10, ^Cstrace: Process 28 detached
<detached ...>
iptables-tailer
```
### kube-iptables-tailer

1. Поднимаем в GKE кластер

2. Устанавливаем iptables-tailer - предварительно все манифесты конвертированы в формат TF (нашел причину - почему в прежних заданиях это не удавалось - провайдер не считывает из кубконфига текущий неймспейс - и при проверке не находит создаваемых ресурсов. Решает пока костылем - указанием неймспейса через локальную переменную и передачей ее в манифест в явном виде 😔 )

``` sh
cd /kit/operator && terraform init &&  terraform  apply -auto-approve  
```

```
kubernetes_manifest.role_netperf_operator: Creating...
kubernetes_manifest.crd_netperfs_app_example_com: Creating...
kubernetes_manifest.rolebinding_default_account_netperf_operator: Creating...
kubernetes_manifest.deployment_netperf_operator: Creating...
kubernetes_manifest.role_netperf_operator: Creation complete after 1s
kubernetes_manifest.crd_netperfs_app_example_com: Creation complete after 1s
kubernetes_manifest.rolebinding_default_account_netperf_operator: Creation complete after 1s
kubernetes_manifest.deployment_netperf_operator: Creation complete after 1s
```

3. Запускаем наш тест

cd /kit/test_app && terraform init &&  terraform  apply -auto-approve  
Поскольку докуентация пишется позднее - вывод уже правильный ))

```
Events:
  Type    Reason     Age   From                                                        Message
  ----    ------     ----  ----                                                        -------
  Normal  Scheduled  17s   default-scheduler                                           Successfully assigned default/netperf-server-6537c3de0913 to gke-av-k8s-cluster-av-k8s-node-pool-ccca4fb7-hz2m
  Normal  Pulled     16s   kubelet, gke-av-k8s-cluster-av-k8s-node-pool-ccca4fb7-hz2m  Container image "tailoredcloud/netperf:v2.7" already present on machine
  Normal  Created    16s   kubelet, gke-av-k8s-cluster-av-k8s-node-pool-ccca4fb7-hz2m  Created container netperf-server-6537c3de0913
  Normal  Started    15s   kubelet, gke-av-k8s-cluster-av-k8s-node-pool-ccca4fb7-hz2m  Started container netperf-server-6537c3de0913
```




4. Загружаем сетевую политику

``` sh
cd /kit/networkpolicy && terraform init &&  terraform  apply -auto-approve  

kubernetes_manifest.netperf_example: Creating...
kubernetes_manifest.networkpolicy_netperf_calico_policy: Creating...
kubernetes_manifest.networkpolicy_netperf_calico_policy: Creation complete after 0s
kubernetes_manifest.netperf_example: Creation complete after 0s
```

```
NAME                    AGE
netperf-calico-policy   84s
```

Прогоняем наше тест еще раз - видим проблемы

``` sh
Status:
  Client Pod:          netperf-client-6537c3de0913
  Server Pod:          netperf-server-6537c3de0913
  Speed Bits Per Sec:  0
  Status:              Started test
Events:                <none>
```

Видим проблемы при прогоне сетевых тестов

```
gke-av-k8s-cluster-av-k8s-node-pool-ccca4fb7-hz2m /home/appuser # iptables --list -nv | grep LOG
    0     0 LOG        all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:XWC9Bycp2Xf7yVk1 */ LOG flags 0 level 5 prefix "calico-packet: "
   27  1620 LOG        all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:B30DykF1ntLW86eD */ LOG flags 0 level 5 prefix "calico-packet: "
```

5. Загружаем iptables-tailer

``` sh
cd /kit/iptables-tailer && terraform init &&  terraform  apply -auto-approve  

kubernetes_manifest.daemonset_kube_iptables_tailer: Creating...
kubernetes_manifest.daemonset_kube_iptables_tailer: Creation complete after 0s
```

```

Events:
Type     Reason        Age                  From                  Message
----     ------        ----                 ----                  -------
Warning  FailedCreate  6s (x16 over 2m50s)  daemonset-controller  Error creating: pods "kube-iptables-tailer-" is forbidden: error looking up service account kube-system/kube-iptables-tailer: serviceaccount "kube-iptables-tailer" not found

```

Фиксим

terraform apply -auto-approve  

kubernetes_manifest.clusterrolebinding_kube_iptables_tailer: Creating...
kubernetes_manifest.clusterrole_kube_iptables_tailer: Creating...
kubernetes_manifest.serviceaccount_kube_iptables_tailer: Creating...
kubernetes_manifest.clusterrolebinding_kube_iptables_tailer: Creation complete after 0s
kubernetes_manifest.clusterrole_kube_iptables_tailer: Creation complete after 0s
kubernetes_manifest.serviceaccount_kube_iptables_tailer: Creation complete after 0s

Деймонсет успешно создался 

``` sh
Events:
  Type    Reason            Age   From                  Message
  ----    ------            ----  ----                  -------
  Normal  SuccessfulCreate  22s   daemonset-controller  Created pod: kube-iptables-tailer-xc9tv
```

6.  Создаем

``` sh
cd tailer && terraform  init   &&  terraform apply -auto-approve        
kubernetes_manifest.daemonset_kube_iptables_tailer: Creating...
kubernetes_manifest.daemonset_kube_iptables_tailer: Creation complete after 1s

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Прогоняем тесты

```
cd /kit/test_app && terraform destroy  -auto-approve  &&  terraform  apply -auto-approve  
```

Events:
  Type     Reason      Age    From                                                        Message
  ----     ------      ----   ----                                                        -------
  Normal   Scheduled   2m58s  default-scheduler                                           Successfully assigned default/netperf-server-6cfe6ef7cbe9 to gke-av-k8s-cluster-av-k8s-node-pool-68b39fc6-x88r
  Normal   Pulled      2m58s  kubelet, gke-av-k8s-cluster-av-k8s-node-pool-68b39fc6-x88r  Container image "tailoredcloud/netperf:v2.7" already present on machine
  Normal   Created     2m58s  kubelet, gke-av-k8s-cluster-av-k8s-node-pool-68b39fc6-x88r  Created container netperf-server-6cfe6ef7cbe9
  Normal   Started     2m57s  kubelet, gke-av-k8s-cluster-av-k8s-node-pool-68b39fc6-x88r  Started container netperf-server-6cfe6ef7cbe9
  Warning  PacketDrop  2m56s  kube-iptables-tailer                                        Packet dropped when receiving traffic from 10.88.2.38
  Warning  PacketDrop  45s    kube-iptables-tailer                                        Packet dropped when receiving traffic from netperf-client-6cfe6ef7cbe9 (10.88.2.38)


  Фух - вроде все полетело 😃

7. Фиксим полиси и деймонсет. Вроде работает.