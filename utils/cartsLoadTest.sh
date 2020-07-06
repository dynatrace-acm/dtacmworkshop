#!/bin/bash

kubectl create ns loadgen

kubectl apply -f ../utils/cartsloadgen.yaml
