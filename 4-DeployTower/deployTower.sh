#!/bin/bash

kubectl create -f ../manifests/ansible-tower/namespace.yml
kubectl create -f ../manifests/ansible-tower/deployment.yml
kubectl create -f ../manifests/ansible-tower/service.yml

echo "Waiting to Ansible Tower to start..."
sleep 120

../utils/configureAnsible.sh