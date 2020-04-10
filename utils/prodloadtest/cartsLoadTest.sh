#!/bin/bash

kubectl apply -f ../../manifests/prodload/k8s-prodload-ns.yaml
kubectl apply -f ../../manifests/prodload/k8s-prodload-deployment.yaml