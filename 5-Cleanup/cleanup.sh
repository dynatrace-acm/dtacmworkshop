#!/bin/bash

#stop Carts Load Test
export CARTS_LOADTEST_PID=$(ps -o pid= -C cartsLoadTest.sh)
kill -9 $CARTS_LOADTEST_PID
echo "Carts load test PID $CARTS_LOADTEST_PID was stopped"

#delete pod security policies and CRDs
kubectl delete podsecuritypolicy dynatrace-oneagent
kubectl delete podsecuritypolicy dynatrace-oneagent-operator
kubectl delete crd oneagents.dynatrace.com

#remove cluster role bindings
kubectl delete clusterrolebinding cluster-admin-binding

kubectl -n dev delete rolebinding default-view
kubectl -n production delete rolebinding default-view

#remove namespaces and their objects
kubectl delete ns dev
kubectl delete ns production
kubectl delete ns dynatrace
kubectl delete ns cicd
kubectl delete ns tower