#!/bin/bash

kubectl delete -f ../manifests/ansible-tower/service.yml
kubectl delete -f ../manifests/ansible-tower/deployment.yml
kubectl delete -f ../manifests/ansible-tower/namespace.yml


echo "----------------------------------------------------"
echo "Ansible Tower has been removed"
echo "----------------------------------------------------"