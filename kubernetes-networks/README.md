# Заметки по выполнению домашней работы по теме "Сетевое взаимодействие Pod, взаимодействие Pod, сервисы"

## Добавление проверок Pod
1. В [деплоймент](../kubernetes-intro/web-pod.yaml) пода добавили конфигурацию  проверки доступности
~~~ yaml
readinessProbe:
# Добавимп роверку готовности
httpGet: # веб-сервера отдавать
    path: /index.html # контент
    port: 80
livenessProbe:
tcpSocket: 
    port: 8000
~~~

## Создали деплоймент для нашего фронта

~~~ yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  strategy:
    type: RollingUpdate
    rollingUpdate: 
      maxUnavailable: 0 
      maxSurge: 100%
  template:
    metadata:
      name: web # Название Pod
      labels: # Метки в формате key: value
        app: web
    spec: # Описание Pod
      containers: # Описание контейнеров внутри Pod
        - name: web # А в методичке нет указания называть именно так
          image: avasiliev/web:1.0 # Образ из которого создается контейнер
          readinessProbe:
            # Добавимп роверку готовности
            httpGet: # веб-сервера отдавать
              path: /index.html # контент
              port: 8000
          livenessProbe:
            tcpSocket: 
              port: 8000

          volumeMounts:
            - name: app
              mountPath: /app
      initContainers:
        - name: init-web
          image: busybox:1.32
          volumeMounts:
            - name: app
              mountPath: /app
          command: ["sh", "-c", "wget -O- https://tinyurl.com/otus-k8s-intro | sh"]
      volumes:
        - name: app
          emptyDir: {}

~~~


## Создание [Service](kubernetes-networks/web-svc-cip.yaml)

~~~ yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc-cip
spec:
  selector:
    app: web
  type: ClusterIP
  ports:
  - protocol: TCP  
    port: 80
    targetPort: 8000

~~~

## Включили IPVS
В конфиг мапе kube-proxy отредактировали 
~~~ yaml
ipvs:
  strictARP: true
  
mode: "ipvs"
~~~

## Установка MetalLB

~~~ sh
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl  rand -base64 128)"
~~~

Настроили [балансировщик L2](metallb-config.yaml) 

~~~ yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.17.255.1-172.17.255.255 
~~~

Создали конфигурацию сервиса [LoadBalancer](web-svc-lb.yaml)

~~~ yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc-lb
spec:
  selector:
    app: web
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
~~~

Добавили маршрут до нашего сервисв
~~~ sh
sudo ip route add 172.17.255.0/24 via 172.17.0.2
~~~

## Создание Ingress

~~~ sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml
~~~

Создали конфигурацию [LoadBalancer](nginx-lb.yaml)

~~~ yaml
kind: Service
apiVersion: v1
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  externalTrafficPolicy: Local
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
  ports:
    - { name: http, port: 80, targetPort: http }
    - { name: https, port: 443, targetPort: https }

~~~

Создлали  [Headless-сервис](web-svc-headless.yaml)

~~~ yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: ClusterIP
  clusterIP: None
  selector:
    app: web
  ports:
  - protocol: TCP  
    port: 80
    targetPort: 8000

~~~

Создали правило для [Ingress](web-ingress.yaml)

~~~ yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: web
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /web
            backend:
              serviceName: web-svc
              servicePort: 8000

~~~
