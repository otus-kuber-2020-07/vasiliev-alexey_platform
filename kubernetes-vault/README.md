# Заметки по выполнению домашней работы по теме "Хранилище секретов для приложений. Vault"

##  Создаем кластер в minikube

``` sh
minikube start
```

## Инсталляция hashicorp vault HA в k8s 

Ну как hashicorp не катать  terraform 😄 

``` sh
terraform  apply -auto-approve 
```

``` sh
NAME: vault
LAST DEPLOYED: Sat Oct 17 19:28:06 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get vault
```


## Инициализируем vault

``` sh
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1
```

``` console
Unseal Key 1: e+G7FNoovgSeVISu10Gp68CFYxkI53kSUoC2XjE7yBc=

Initial Root Token: s.G6ELw9hdtdLfNsQ8VATZWSXz
```

## Распечатываем vault
``` sh
  kubectl exec -it vault-0 -- vault operator unseal 'e+G7FNoovgSeVISu10Gp68CFYxkI53kSUoC2XjE7yBc='  
  kubectl exec -it vault-1 -- vault operator unseal 'e+G7FNoovgSeVISu10Gp68CFYxkI53kSUoC2XjE7yBc='
  kubectl exec -it vault-2 -- vault operator unseal 'e+G7FNoovgSeVISu10Gp68CFYxkI53kSUoC2XjE7yBc='

```

```
kubectl exec -it vault-1 -- vault status
```

``` yaml
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.5.2
HA Enabled         true

```


## Залогинимся в vault
```
kubectl exec -it vault-0 -- vault login
```
``` console
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.G6ELw9hdtdLfNsQ8VATZWSXz
token_accessor       1dFjc1Qf4x501mm3Ak8l8qm1
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

``` sh
kubectl exec -it vault-0 --  vault auth list                                                                                                                            

Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_336b53e4    token based credentials
```


``` sh
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
kubectl exec -it vault-0 -- vault secrets list --detailed
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
```
``` sh
/ $ vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus
/ $ vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
```

### Включим авторизацию через k8s
``` sh
kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl exec -it vault-0 --  vault auth list
```

``` sh
/ $  vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_e1e67fc2    n/a
token/         token         auth_token_72fd1aff         token based credentials
```

## Создадим yaml для ClusterRoleBinding

Конвертируем файл в [манифест формата Terraform](./vault-auth-service-account.tf) + добавляем провайдера


## Подготовим переменные для записи в конфиг k8s авторизации

``` sh
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" |base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" |base64 --decode; echo)
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')
```

## Запишем конфиг в vault
``` sh
kubectl exec -it vault-0 -- vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST"   kubernetes_ca_cert="$SA_CA_CRT"
```

## создадим политку и роль в vault

``` sh
kubectl cp otus-policy.hcl vault-0:/tmp/
kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus  bound_service_account_names=vault-auth bound_service_account_namespaces=default policies=otus-policy  ttl=24h
```

## Проверим как работает авторизация
``` sh
kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7 
apk add curl jq
```

``` sh
VAULT_ADDR=http://vault:8200
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl --request POST  --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq 
TOKEN=$(curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')

```

``` sh
curl --silent --header "X-Vault-Token:s.ohRK5DMO3KhKerE7hWwTk2ok" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "request_id": "5e34edbe-8b4a-625b-7644-6d1c5be1d664",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```


``` sh
curl --silent --header "X-Vault-Token:s.ohRK5DMO3KhKerE7hWwTk2ok" $VAULT_ADDR/v1/otus/otus-rw/config | jq

```

``` sh
curl --silent --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.ohRK5DMO3KhKerE7hWwTk2ok" $VAULT_ADDR/v1/otus/otus-rw/config1
```
Ловим ошибку

``` json
{
  "errors": [
    "1 error occurred:\n\t* permission denied\n\n"
  ]
}
```

меняем политику

``` yaml
path "otus/otus-rw/*" {
    capabilities = ["read", "create", "update", "list"]
} 
```

катаем заного
``` sh
curl --silent --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.ohRK5DMO3KhKerE7hWwTk2ok" $VAULT_ADDR/v1/otus/otus-rw/config

```

## Use case использования авторизации через k8s 


``` sh
kubectl create configmap example-vault-agent-config --from-file=./configs-k8s/
kubectl apply -f ./configs-k8s/example-k8s-spec.yml --record
```


###
законнектится к поду nginx и вытащить оттуда index.html

``` sh
root@vault-agent-example:/# curl localhost
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```

## создадим CA на базе vault

### Включим pki секретс
``` sh
kubectl exec -it vault-0 -- vault secrets enable pki 
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki 
kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal  common_name="exmaple.ru"  ttl=87600h > /tmp/CA_cert.cr
```

### пропишем урлы для ca и отозванных сертификатов
``` sh
kubectl exec -it vault-0 -- vault write pki/config/urls    issuing_certificates="http://vault:8200/v1/pki/ca"  crl_distribution_points="http://vault:8200/v1/pki/crl"


```

### создадим промежуточный сертификат

``` sh
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
kubectl exec -it vault-0 -- vault write -format=json/pki_int/intermediate/generate/internal  common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr

```

### пропишем промежуточный сертификат в vault

``` sh
kubectl cp pki_intermediate.csr vault-0:./tmp/

kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

kubectl cp intermediate.cert.pem vault-0:./tmp/

kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem

```


### Создадим и отзовем новые сертификаты

* Создадим роль для выдачи с ертификатов
``` sh
kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
```

* Создадим и отзовем сертификат
``` sh
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"
```

``` yaml
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUQXvSlSqeGRftznQ4lcbJWBmbDdIwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDEwMTgxNzAwMzdaFw0yNTEw
MTcxNzAxMDdaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMmxsF0UUlrN
cwuQXNqwgrqB7QcBkwmtS8XUPIPMLmYKytcWaCVByPIGrLYCphsMPaITNTafWsfi
AosubCiOndJALDYo342HUWzPLBkNitPg56EQEiLUJ391JUBXVEdHw3/5Yi8z+Kii
GFW2CawCO3qjGTl0IEynretqJ3CQGHRMaLVwMeBxQdYZsWKYRhPU2qyC8JO7is9g
zxrwTy0cKwx4ICTfdtnrLVnDWcpmZOdH5j+kQ/QxKyJ7M1GMMyL8pWT1sgpsLNQs
3WnYEIN8dPC0Tz5aOajAby0088E7NA7oSeoKFmrRwIlFR1cdXeu2X0QszyUdUf2I
imywY717vvMCAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUQLrpwgHP9n8wKe/TG1KHSafrh+UwHwYDVR0jBBgwFoAU
hs3ZiuwFp1IIghz33pO0+G/uUIMwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
KtiLdNrii0ZbD7CJ7aLREsFuh48/elxSg2TI/8nUVdTcq83+6dTIRroSTVea6esf
vs4L1jfvL9kMIyc7awxpN9HzgWMLIiAZhOWZDWRGx00laW707ZNYqjim7eAsD59K
TYFfW+ScOuaBfD9EIDVUKgQOu6MUelTNWpxKyNQeTCPY/aI7zwvUW3bZj5CFi2ay
lGzzORPOWFKMP5TuOHrDEqWoksu5iUAv6g1qg6VIwMoJmIFv86aXb5ZI57nsvpVg
pyXFTgvMp/usDINbUWkIKJv5HM1IiIkgpCtehEIsXak4Nq/hBG9z93RimjUpmcWx
JwyJbdxb1xcBGWEOeUzkkg==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUZRT+2WFjDoBh2zqhSrorhCyISs8wDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIwMTAxODE3MDQyM1oXDTIwMTAxOTE3MDQ1MlowHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDH
ET6UA1hSyH5BOVud/qj/AmsLx/JcoMETe3GNMRl+g5D1wMLKZvhOHe9jdh5XfTMp
6qCIYZMB4iISAHnHg+DWAW5TdzdFO+pmpAAKP6gO0xrpPNe1MEHRaweZaMmj7g/d
AK5LQnTdwDkvwBPIS8LC+y0Byws632CCR/NuweZnZp8OoswXjiC59B2s2bo3T/Zu
Os+EP1LGehgKw2ibUc0jtRkKW8i9xqXKCCYsFkFkBbWk2UB92ewN4b5oRB5scUjt
tRCJdFtP39nxOeQfDTmHITJ7SZbvobdA7OLiWmtHW3veqSKvBTaEa/WH2u+Cww94
lK49hfOP8zTJ1z80CLpTAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUKVNlQXLVRsPur2Eu
nQhw6TYdG7UwHwYDVR0jBBgwFoAUQLrpwgHP9n8wKe/TG1KHSafrh+UwHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBAKHrCSY7
2VEi0kRVgA4lj5jxdCrybn97iwtLMNR2LZxIxkJ4gHVGIQe4xJsQHmitbGieg+qC
qTB+gHgb1gAtlb2Sc4U8azUYzAeTyrIqKjng0hg7IIErVIhwtgUWmYGCjZwQNxQT
S1NM305EsF1/hJ5Z+1B704xHvHcFMF/1wS5VbpcPhyvB2aN+wJ3oL1fEt2jMy9T4
j0BP28czz2ZTHcPTRodaZz8KnTyiKALRofT5sEdKK73aNw40u7J3m0UChd8IIG2t
SYJXzox2e/solYsH4ftWkwWp5v9tI6eAx9IxKqAQYg/RQKwEdjCXuTtt9bRO1i2q
FlcabbLaP1WL/Ic=
-----END CERTIFICATE-----
expiration          1603127092
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUQXvSlSqeGRftznQ4lcbJWBmbDdIwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMDEwMTgxNzAwMzdaFw0yNTEw
MTcxNzAxMDdaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMmxsF0UUlrN
cwuQXNqwgrqB7QcBkwmtS8XUPIPMLmYKytcWaCVByPIGrLYCphsMPaITNTafWsfi
AosubCiOndJALDYo342HUWzPLBkNitPg56EQEiLUJ391JUBXVEdHw3/5Yi8z+Kii
GFW2CawCO3qjGTl0IEynretqJ3CQGHRMaLVwMeBxQdYZsWKYRhPU2qyC8JO7is9g
zxrwTy0cKwx4ICTfdtnrLVnDWcpmZOdH5j+kQ/QxKyJ7M1GMMyL8pWT1sgpsLNQs
3WnYEIN8dPC0Tz5aOajAby0088E7NA7oSeoKFmrRwIlFR1cdXeu2X0QszyUdUf2I
imywY717vvMCAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUQLrpwgHP9n8wKe/TG1KHSafrh+UwHwYDVR0jBBgwFoAU
hs3ZiuwFp1IIghz33pO0+G/uUIMwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
KtiLdNrii0ZbD7CJ7aLREsFuh48/elxSg2TI/8nUVdTcq83+6dTIRroSTVea6esf
vs4L1jfvL9kMIyc7awxpN9HzgWMLIiAZhOWZDWRGx00laW707ZNYqjim7eAsD59K
TYFfW+ScOuaBfD9EIDVUKgQOu6MUelTNWpxKyNQeTCPY/aI7zwvUW3bZj5CFi2ay
lGzzORPOWFKMP5TuOHrDEqWoksu5iUAv6g1qg6VIwMoJmIFv86aXb5ZI57nsvpVg
pyXFTgvMp/usDINbUWkIKJv5HM1IiIkgpCtehEIsXak4Nq/hBG9z93RimjUpmcWx
JwyJbdxb1xcBGWEOeUzkkg==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAxxE+lANYUsh+QTlbnf6o/wJrC8fyXKDBE3txjTEZfoOQ9cDC
ymb4Th3vY3YeV30zKeqgiGGTAeIiEgB5x4Pg1gFuU3c3RTvqZqQACj+oDtMa6TzX
tTBB0WsHmWjJo+4P3QCuS0J03cA5L8ATyEvCwvstAcsLOt9ggkfzbsHmZ2afDqLM
F44gufQdrNm6N0/2bjrPhD9SxnoYCsNom1HNI7UZClvIvcalyggmLBZBZAW1pNlA
fdnsDeG+aEQebHFI7bUQiXRbT9/Z8TnkHw05hyEye0mW76G3QOzi4lprR1t73qki
rwU2hGv1h9rvgsMPeJSuPYXzj/M0ydc/NAi6UwIDAQABAoIBABTDo7dkse3Qo/rB
tODCE3amFexgqtMmoX0avzlvCa28o34+4RKjsvrS/IlvZLLTiGay5pPTObZUlCE0
k39QLj+kXpGuOcGrAkQ6jxaClVEWjBQQGJ/5rKPfeidyWrYSuuzeiU+oWvBWgKCO
dIHMBUC5WnR5bW5ypmpwft/qsdHPH03rdb8UXcF8CxyGiQV/aKnrIHl2ARTZiKfQ
2LPQ9OFJQ9TK5cl3P8TZUrqHoJwvp+v3qELCENwaPnMXdF2APVv3AUxPdnY/yArq
a+TlDKGOgudh3XIduQqE5MNRbg4PLq7BsGFylYiiUCYY9VIxzM3TPoH9NLzWG8Ay
7FyniUECgYEA8RPMxmFlDwgXGrFhHOsbrZFWcVq994b1w8lTW/D2OAVxca/HfYSM
6sj8+sGe2FPBGAPRHxl+L2lSxk1+/XukfxyHwQCl34Fsbd8J6qw6aHOrzEx2/XMV
mRcxsN9uubnivPudyJzFTz7TumgBr4dFs7NuY435H5JSMomzWs+KJOkCgYEA02O9
KzcOEx+YiG20BnPiRAULhkkE7mPRt4TwZ5D68EJvM8jgSw9k00RpG2SvnaYNowkn
uorEwfRIeEd8zEVDBPqBv3UBT2cocFBo8O+RTI84twBbezqEzzY91/oAKgHQ8n5e
OIyry0oYIHILc/44CnIC7XeJlI0Gsp91qMo1j9sCgYBi/e1lPJMB1CGgnVuyQzyP
ThG/5DIDVVDPv3jSVSTVpi6KL1LsUKSIuFVhJmZykBnHIbIaYh51m3sY4LOXpNDM
PUvlTb3PBFcg2qg4y9YEFBNkhbWKp1okDekipuzRqOnZDj0hJnbC7pqEfbbLe/F8
M97NVHwKocvM4sxaKsSgGQKBgATyqrTePwgXjzxyROp5v+wTqidkgicKUxhWlkH2
VMlW5L9zjjxzicqgKU2o16t6/Yq5ZiKpqN1ZWHDoS3WEkYMGUg8nL/ap1Xp7h1lM
YjxGhe9SpNGHlyA6hswNX/+bt0ZVyuLL+CF0BIiN4tK+OpWUAZmJWMEPY/6+WMSw
pvxNAoGAYuJBYqwccOP9VINqyKvM/MauAyeu4EJBWgldHa2/uqURWawhZ9q7WBlH
DD4V2L5UKWHb47jylBDVtjuVSg8scrXW4Yp9TXF5EMUP7qYj6xkr5KFg9wfiwfyR
CkXL+65WzShSDc7T3Yo682xgubGR4oSore9Q7gALskzG/vJYG88=
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       65:14:fe:d9:61:63:0e:80:61:db:3a:a1:4a:ba:2b:84:2c:88:4a:cf
```

 
``` sh
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="65:14:fe:d9:61:63:0e:80:61:db:3a:a1:4a:ba:2b:84:2c:88:4a:cf"
```

``` yaml
Key                        Value
---                        -----
revocation_time            1603040776
revocation_time_rfc3339    2020-10-18T17:06:16.932631364Z
```

---
## Материалы
* [Vault Agent with Kubernetes](https://learn.hashicorp.com/tutorials/vault/agent-kubernetes)  
* [Демо от Гугла - Vault on GKE](https://github.com/GoogleCloudPlatform/gke-vault-demo)
* [![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/oDdDPU6moTs/0.jpg)](https://www.youtube.com/watch?v=oDdDPU6moTs)

https://github.com/hashicorp/vault-guides