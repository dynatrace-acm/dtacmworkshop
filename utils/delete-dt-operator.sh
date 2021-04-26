#!/bin/bash

kubectl delete -n dynatrace dynakube --all


kubectl delete -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes.yaml
kubectl delete secret dynakube -n dynatrace

kubectl delete namespace dynatrace