#!/bin/bash

kubectl create -f ../manifests/k8s-namespaces.yml

kubectl apply -f ../manifests/backend-services/user-db/dev/


kubectl apply -f ../manifests/backend-services/shipping-rabbitmq/dev/


kubectl apply -f ../manifests/backend-services/carts-db/

kubectl apply -f ../manifests/backend-services/catalogue-db/

kubectl apply -f ../manifests/backend-services/orders-db/

kubectl apply -f ../manifests/sockshop-app/dev/

#Create ClusterRoleBinding View to pull labels and annotations for dev namespace
kubectl -n dev create rolebinding default-view --clusterrole=view --serviceaccount=dev:default


