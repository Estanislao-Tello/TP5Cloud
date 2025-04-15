# TP5Cloud
En primera instancia, debemos descargar Minikube y el driver Docker.

Además, debemos descargar Kubectl, que es la herramienta que permite comunicarnos con Kubernetes mediante lineas de código.
También debemos descargar GIT para poder bajar los repositorios.

Luego de haber descargado todo, creamos una carpeta y nos dirigimos a ella utilizando el comando cd. 
Dentro de ella:
- git init
- git clone https://github.com/Estanislao-Tello/TP5Cloud.git
- git clone https://github.com/Estanislao-Tello/Personal-LP.git

--------------------------------------

Luego, levantamos Minikube
- minikube start --mount --mount-string="/home/lao/TP5Cloud/Personal-LP:/mnt/web"

A continuación, creamos los manifiestos:
- cd /home/lao/TP5Cloud
- mkdir manifiestos
- cd /home/lao/TP5Cloud/TP5Cloud/manifiestos
- mkdir deployments services volumes

Una vez creados los .yaml, debemos usar el siguiente comando en cada una de las carpetas
- kubectl apply -f .

Nuestro pod debería estar levantándose. Podemos ver el estado del mismo con: 
- kubectl get pods 
El nombre será: static-site-XXX-XXX. El estado será Pending, ContainerCreating y por último Running.

Una vez en Running, podremos levantar el servicio con nuestro .html con el siguiente script:
- minikube service static-site-service

Esto abrirá una ventana en el navegador con nuestra página.

Siguiendo estos pasos, ya se ha levantado tu primer servicio con Kubernetes.

Si desea sumar un extra y agregar funcionalidad al archivo ingress, haga lo siguiente:
- minikube addons enable ingress (es normal que tarde)

Luego, haremos un "kubectl apply -f ." como hicimos con los manifiestos anteriormente, pero en la carpeta ingress.

Una vez hecho esto, debemos obtener la IP de Minikube con el siguiente comando
- minikube ip

Por último, debemos configurar a la máquina para que no solo se pueda acceder desde el puesto, sino también por una URL propia:
- echo "192.168.49.2 local.service" | sudo tee -a /etc/hosts

Siguiendo estos pasos, el ingress queda correctamente configurado. Pruebe abriendo su navegador y buscando "http://local.service".
