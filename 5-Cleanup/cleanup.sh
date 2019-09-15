#!/bin/bash

#stop Carts Load Test
export CARTS_LOADTEST_PID=$(ps -o pid= -C cartsLoadTest.sh)
kill -9 $CARTS_LOADTEST_PID

#remove namespaces and their objects
kubectl delete ns dev
kubectl delete ns production
kubectl delete ns dynatrace
kubectl delete ns cicd
kubectl delete ns tower