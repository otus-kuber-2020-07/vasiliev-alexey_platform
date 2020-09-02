# Custom Resource Definitions. Operators

* Определяем  метаданные объекта -  CustomResourceDefinition

Для указания обязательности  атрибутов создаваемого объекта  используется конструкция вида

~~~ yaml
required:
  - apiVersion
  - kind
  - metadata
~~~

Создаем venv ( ну мы же не будем стрелять себе в ногу)
~~~ sh
python3 -m venv env 
~~~

Устанавливаем kopf

~~~ sh
pip3 install kopf
pip3 install kubernetes
~~~

? Вопрос:почему объект создался, хотя мы создали CR, до того, как запустили контроллер?
потому-что, EventSourcing :)

* Создали свой [оператор](build/mysql-operator.py)

* Запаковали его в [Docker](build/Dockerfile)

* Создали манифесты развертывания, и указали свой образ

* закатали, и провреили что все работает