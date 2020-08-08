# Заметки по выполнению домашней работы по теме "Знакомство с Kubernetes, основные понятия и архитектура"


# Устновка  kubectl
* Уже установлен
~~~
kubectl  version
Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.3", GitCommit:"2e7996e3e2712684bc73f0dec0200d64eec7fe40", GitTreeState:"clean", BuildDate:"2020-05-20T12:52:00Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.0", GitCommit:"70132b0f130acc0bed193d9ba59dd186f0e634cf", GitTreeState:"clean", BuildDate:"2019-12-07T21:12:17Z", GoVersion:"go1.13.4", Compiler:"gc", Platform:"linux/amd64"}
~~~

# Устновка  minikube
* Был устновлен ранее 

~~~ sh
➜  .github git:(kubernetes-prepare) ✗  minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
~~~


# k9s
Пропустил

## Задание: Почему все поды восстановились
* kube-apiserver  - статичный под, он управляется напрямую kubelet демоном. Поэтому при удалении он будет поднят автоматически.
* kube-proxy - DaemonSet, и он тоже управляется kubelet
* Другие Pod-ы поднимаются, потому что в из политики заложен рестарт
  ~~~ yaml
  restartPolicy: Always
  ~~~
