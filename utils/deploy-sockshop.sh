#!/bin/bash

# Deploy SockShop to dev and production namespaces
kubectl create -f ../manifests/k8s-namespaces.yml

kubectl apply -f ../manifests/backend-services/user-db/dev/
kubectl apply -f ../manifests/backend-services/user-db/production/

kubectl apply -f ../manifests/backend-services/shipping-rabbitmq/dev/
kubectl apply -f ../manifests/backend-services/shipping-rabbitmq/production/

kubectl apply -f ../manifests/backend-services/carts-db/

kubectl apply -f ../manifests/backend-services/catalogue-db/

kubectl apply -f ../manifests/backend-services/orders-db/

kubectl apply -f ../manifests/sockshop-app/dev/
kubectl apply -f ../manifests/sockshop-app/production/

#Create ClusterRoleBinding View to pull labels and annotations for dev namespace
kubectl -n dev create rolebinding default-view --clusterrole=view --serviceaccount=dev:default

#Create ClusterRoleBinding View to pull labels and annotations for prod namespace
kubectl -n production create rolebinding default-view --clusterrole=view --serviceaccount=production:default
