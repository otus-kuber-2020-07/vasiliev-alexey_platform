# CSI. Обзор подсистем хранения данных в Kubernetes

## Цель: 

* В данном дз студенты научатся взаимодействовать с CSI
* Изучат нюансы хранения данных для Stateful приложений

Все действия описаны в методическом указании

---

## Решение

1 Развертываем кластер k8s через решение k1s

``` sh
cd single && vagrant up  
 vagrant ssh -c 'cat /home/vagrant/.kube/config' > ~/.kube/config
```

2 Устанавливаем [CSI Host Path Driver](https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/docs/deploy-1.17-and-later.md)

``` sh
# клоним репу
git clone https://github.com/kubernetes-csi/csi-driver-host-path.git

# install
cd ~/csi-driver-host-path/deploy/kubernetes-latest
```

Проверяем поды

``` sh
➜  single git:(master) ✗ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
csi-hostpath-attacher-0      1/1     Running   0          2m5s
csi-hostpath-provisioner-0   1/1     Running   0          2m3s
csi-hostpath-resizer-0       1/1     Running   0          2m2s
csi-hostpath-snapshotter-0   1/1     Running   0          2m1s
csi-hostpath-socat-0         1/1     Running   0          2m
csi-hostpathplugin-0         3/3     Running   0          2m3s
```

3 Устанавливаем StorageClass

``` sh
cd hw && kubectl apply -f storage-class.yaml
```

4  Создаем PVC

``` sh
cd hw && kubectl apply -f storage-pvc.yaml
```

4  Создаем Pod

``` sh
cd hw && kubectl apply -f storage-pod.yaml
```

5. проверяем 

``` sh
➜  single git:(master) ✗ kubectl get po,pv,pvc 
NAME                             READY   STATUS    RESTARTS   AGE
pod/csi-hostpath-attacher-0      1/1     Running   0          43m
pod/csi-hostpath-provisioner-0   1/1     Running   0          43m
pod/csi-hostpath-resizer-0       1/1     Running   0          43m
pod/csi-hostpath-snapshotter-0   1/1     Running   0          43m
pod/csi-hostpath-socat-0         1/1     Running   0          43m
pod/csi-hostpathplugin-0         3/3     Running   0          43m
pod/storage-pod                  1/1     Running   0          63s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS      REASON   AGE
persistentvolume/pvc-11344a59-3026-4928-9efa-ca02a553d9e1   1Gi        RWO            Delete           Bound    default/storage-pvc   csi-hostpath-sc            2m21s

NAME                                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
persistentvolumeclaim/storage-pvc   Bound    pvc-11344a59-3026-4928-9efa-ca02a553d9e1   1Gi        RWO            csi-hostpath-sc   2m21s
```

Проврим - что сосздалось в поде 

``` yaml
Name:         storage-pod
Namespace:    default
Priority:     0
Node:         k1s/192.168.33.110
Start Time:   Sun, 01 Nov 2020 18:34:41 +0300
Labels:       
Annotations:  Status:  Running
IP:           10.244.0.10
IPs:
  IP:  10.244.0.10
Containers:
  storage-pod:
    Container ID:   docker://2b41a3185d7e19fc170ae59a55a9e284d9caa7a7a752cf13cc2ad0a3c6a27a45
    Image:          nginx
    Image ID:       docker-pullable://nginx@sha256:ed7f815851b5299f616220a63edac69a4cc200e7f536a56e421988da82e44ed8
    Port:           
    Host Port:      
    State:          Running
      Started:      Sun, 01 Nov 2020 18:35:13 +0300
    Ready:          True
    Restart Count:  0
    Environment:    
    Mounts:
      /data from storage-csi-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-bxfd5 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  storage-csi-volume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  storage-pvc
    ReadOnly:   false
  default-token-bxfd5:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-bxfd5
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason                  Age    From                     Message
  ----    ------                  ----   ----                     -------
  Normal  Scheduled               8m39s  default-scheduler        Successfully assigned default/storage-pod to k1s
  Normal  SuccessfulAttachVolume  8m39s  attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-11344a59-3026-4928-9efa-ca02a553d9e1"
  Normal  Pulling                 8m22s  kubelet, k1s             Pulling image "nginx"
  Normal  Pulled                  8m7s   kubelet, k1s             Successfully pulled image "nginx" in 14.993351893s
  Normal  Created                 8m7s   kubelet, k1s             Created container storage-pod
  Normal  Started                 8m7s   kubelet, k1s             Started container storage-pod
```

Видимо что все успешно забиндилось