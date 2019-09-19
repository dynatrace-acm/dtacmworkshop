#!/bin/bash

export CARTS_PODS_AVAILABLE=$(kubectl get deployments/carts -n production -o json | jq '.status.readyReplicas')

while [ -z "$CARTS_PODS_AVAILABLE" ] || [ "$CARTS_PODS_AVAILABLE" == null ]
do
    echo "The value of carts pods is " $CARTS_PODS_AVAILABLE

    echo "sleeping 30 seconds"
    sleep 30
    CARTS_PODS_AVAILABLE=$(kubectl get deployments/carts -n production -o json | jq '.status.readyReplicas')

    if [ "$CARTS_PODS_AVAILABLE" -eq 1 ]
    then
        echo $CARTS_PODS_AVAILABLE
        echo "Beginning Load Test"
    else
        echo $CARTS_PODS_AVAILABLE
        echo "Checking again"
    fi
done

export CARTS_URL=$(kubectl describe svc carts -n production | grep "LoadBalancer Ingress:" | sed 's/LoadBalancer Ingress:[ \t]*//')

i=0
while true
do
    curl -X POST -H "Content-Type: application/json" -d "{\"itemId\":\"03fef6ac-1896-4ce8-bd69-b798f85c6e0b\", \"unitPrice\":\"99.99\"}" http://$CARTS_URL/carts/1/items
    sleep 2

    i=$((i+1))
    if [ $i -ge 100 ]
    then
        curl -X DELETE http://$CARTS_URL/carts/1
    fi
done