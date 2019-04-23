
Sticky Sessions with Ingress
============================

This repo is an example of using the Nginx Ingress controller to create sticky session control so that the client always go back to the same backend.

This example is based on Minikube, and is executed with the following steps once your system is up and running with the Nginx Ingress controller:

Enable ingress on Minikube:
```
$minikube addons enable ingress
```

List Makefile targets:
```
$make help
```

Create certificates:
```
$make mkcerts
```

Set IP in local hosts for domain name:
```
$make localip
```

Deploy test:
```
$make deploy
```

`curl` does not honour the cookies correctly, so use `wget` instead. Test using `wget`:
```
$wget --load-cookies cookies.txt --save-cookies cookies.txt --no-check-certificate https://sticky.test.minikube.local -q -O -
```

Clean up:
```
$make delete
```
