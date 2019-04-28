
Sticky Sessions with Ingress
============================

This repo is an example of using the Nginx Ingress controller to create sticky session control so that the client always go back to the same backend.


Setting up Ingress controller
=============================

Details can be found at https://kubernetes.github.io/ingress-nginx/deploy/ .

On minikube it is as simple as:
```
$ minikube addons enable ingress
```

Setup the LoadBalancer automatically with:
```
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/cloud-generic.yaml | grep -v externalTrafficPolicy | kubectl apply -f -
```
`grep -v externalTrafficPolicy` removes the `externalTrafficPolicy: Local` directive which is currently not supported on CC (related: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip).

Or on some other configuration eg: magnum, then the following can be used:
```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml
```

It is possible to modify the Ingress Controller Pod so that it listens on 80/443, but it is generally a better idea to find the nodePort created above eg:
```
$ kubectl get svc -n ingress-nginx
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx   NodePort   10.254.244.56   <none>        80:30692/TCP,443:31610/TCP   84m
```
And then create an Octavia LoadBalancer TCP/443 pointing to 31610 (in the above case) with all k8s master nodes in the member list.

Running the Example
===================

This example is based on Minikube, and is executed with the following steps once your system is up and running with the Nginx Ingress controller:

List Makefile targets:
```
$ make help
```

Create certificates:
```
$ make mkcerts
```

Set IP in local hosts for domain name:
```
$ make localip
```

Deploy test:
```
$ make deploy
```

`curl` does not honour the cookies correctly, so use `wget` instead. Test using `wget`:
```
$ wget --load-cookies cookies.txt --save-cookies cookies.txt --no-check-certificate https://sticky.test.minikube.local -q -O -
```

Clean up:
```
$ make delete
```
