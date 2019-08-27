#!/bin/bash

kubectl delete -f manifests/sockshop-app/dev/

kubectl delete -f manifests/backend-services/orders-db/
kubectl delete -f manifests/backend-services/catalogue-db/
kubectl delete -f manifests/backend-services/carts-db/

kubectl delete -f manifests/backend-services/shipping-rabbitmq/dev/
kubectl delete -f manifests/backend-services/user-db/dev/

kubectl delete -f manifests/k8s-namespaces.yml
