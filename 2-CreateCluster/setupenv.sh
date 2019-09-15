#!/bin/bash


export API_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceApiToken')
export PAAS_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatracePaaSToken')
export TENANTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceTenantID')
export ENVIRONMENTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceEnvironmentID')



usage()
{
    echo 'Usage : ./setupenv.sh API_TOKEN PAAS_TOKEN TENANTID ENVIRONMENTID (optional if a SaaS deployment)'
    exit
}

echo "Creating GKE Cluster with the following credentials: "
echo "API_TOKEN = $API_TOKEN"
echo "PAAS_TOKEN = $PAAS_TOKEN"
echo "TENANTID = $TENANTID"
echo "ENVIRONMENTID = $ENVIRONMENTID"

read -p "Is this all correct? (y/n) : " -n 1 -r

echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Creating GKE Cluster..."
    gcloud container clusters create acmworkshop --zone=us-central1-a --num-nodes=3 --machine-type=n1-highmem-2 --image-type=Ubuntu
else
    exit 1
fi

echo "Cluster created"
echo "Deploying OneAgent Operator"

kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)

kubectl create namespace dynatrace

#LATEST_RELEASE=$(curl -s https://api.github.com/repos/dynatrace/dynatrace-oneagent-operator/releases/latest | grep tag_name | cut -d '"' -f 4)
LATEST_RELEASE=v0.3.1
kubectl create -f https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/kubernetes.yaml

kubectl -n dynatrace create secret generic oneagent --from-literal="apiToken="$API_TOKEN --from-literal="paasToken="$PAAS_TOKEN

if [[ -f "cr.yaml" ]]; then
    rm -f cr.yaml
    echo "Removed cr.yaml"
fi

curl -o cr.yaml https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/cr.yaml

case $ENVIRONMENTID in
        *)
        echo "Managed Deployment"
        sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$TENANTID'.dynatrace-managed.com\/e\/'$ENVIRONMENTID'\/api/' cr.yaml
        ;;
        '')
        echo "SaaS Deplyoment"
        sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$TENANTID'.live.dynatrace.com\/api/' cr.yaml
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

echo "Start Production Load"
nohup ../utils/cartsLoadTest.sh &

echo "Deployment Complete"
