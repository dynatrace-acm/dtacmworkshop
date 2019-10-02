#!/bin/bash

kubectl delete -n dynatrace oneagent --all

LATEST_RELEASE=v0.3.1
kubectl delete -f https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/kubernetes.yaml

kubectl delete namespace dynatrace