#!/bin/bash

export API_TOKEN=$1
export PAAS_TOKEN=$2
export TENANTID=$3
export ENVIRONMENTID=$4 

usage()
{
    echo 'Usage : ./setupenv.sh API_TOKEN PAAS_TOKEN TENANTID ENVIRONMENTID (optional if a SaaS deployment)'
    exit
}

case $# in
        3 | 4)
        ;;
        ?)
        usage
        ;;
esac

echo "Creating GKE Cluster..."

gcloud container clusters create acmworkshop --zone=us-central1-a --num-nodes=1 --machine-type=n1-highmem-2 --image-type=Ubuntu

echo "Cluster created"
echo "Deploying OneAgent Operator"

kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)

kubectl create namespace dynatrace

LATEST_RELEASE=$(curl -s https://api.github.com/repos/dynatrace/dynatrace-oneagent-operator/releases/latest | grep tag_name | cut -d '"' -f 4)
kubectl create -f https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/kubernetes.yaml

kubectl -n dynatrace create secret generic oneagent --from-literal="apiToken="$1 --from-literal="paasToken="$2

if [[ -f "cr.yaml" ]]; then
    rm -f cr.yaml
    echo "Removed cr.yaml"
fi

curl -o cr.yaml https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/cr.yaml

case $# in
        4)
        echo "Managed Deployment"
        sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$3'.dynatrace-managed.com\/e\/'$4'\/api/' cr.yaml
        ;;
        3)
        echo "SaaS Deplyoment"
        sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$3'.live.dynatrace.com\/api/' cr.yaml
        ;;
        ?)
        usage
        ;;
esac

kubectl create -f cr.yaml

echo "Waiting for OneAgent to startup..."

sleep 120

echo "Deploying SockShop Application"

../utils/deploy-sockshop.sh

echo "Deployment Complete"
