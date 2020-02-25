#!/bin/bash


export API_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceApiToken')
export PAAS_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatracePaaSToken')
export TENANTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceTenantID')
export ENVIRONMENTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceEnvironmentID')

if [ -z $1 ];
then
    export K8S_CLUSTER_NAME=acmworkshop
else
    export K8S_CLUSTER_NAME=$1
fi

if hash gcloud 2>/dev/null; then
    echo "Google Cloud"
    export CLOUD_PROVIDER=GKE
elif hash az 2>/dev/null; then
    echo "Azure Cloud"
    export CLOUD_PROVIDER=AKS
else
    echo "No supported Cloud Provider (GCP or AKS) detected."
    exit 1;
fi

echo "Creating $CLOUD_PROVIDER Cluster with the following credentials: "
echo "API_TOKEN = $API_TOKEN"
echo "PAAS_TOKEN = $PAAS_TOKEN"
echo "TENANTID = $TENANTID"
echo "ENVIRONMENTID = $ENVIRONMENTID"
echo "K8S CLUSTER NAME = $K8S_CLUSTER_NAME"
echo "Cloud Provider $CLOUD_PROVIDER"

echo ""
read -p "Is this all correct? (y/n) : " -n 1 -r
echo ""

usage()
{
    echo 'Usage : ./setupenv.sh K8S_CLUSTER_NAME API_TOKEN PAAS_TOKEN TENANTID ENVIRONMENTID (optional if a SaaS deployment)'
    exit
}

deployGKE()
{
    echo "Creating GKE Cluster..."

    gcloud container clusters create $K8S_CLUSTER_NAME --zone=us-central1-a --num-nodes=3 --machine-type=n1-highmem-2 --image-type=Ubuntu

    kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
}

deployAKS()
{
    echo "Creating AKS Cluster..."
    export AKS_RESOURCE_GROUP=ACM

    az group create --name $AKS_RESOURCE_GROUP --location centralus
    az aks create --resource-group $AKS_RESOURCE_GROUP --name $K8S_CLUSTER_NAME --node-count 1 --node-vm-size Standard_B4ms --generate-ssh-keys

    az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $K8S_CLUSTER_NAME
}


if [[ $REPLY =~ ^[Yy]$ ]]; then
    case $CLOUD_PROVIDER in
        GKE)
        deployGKE
        ;;
        AKS)
        deployAKS
        ;;
        *)
        echo "No supported Cloud Provider (GCP or AKS) detected."
        exit 1
        ;;
    esac
else
    exit 1
fi


echo "Cluster created"

echo "Deploying OneAgent Operator"

../utils/deploy-dt-operator.sh

echo "Waiting for OneAgent to startup..."
sleep 120

echo "Deploying SockShop Application"
../utils/deploy-sockshop.sh
echo -e "${YLW}Waiting about 5 minutes for all pods to become ready...${NC}"
sleep 330s

../utils/get-sockshop-urls.sh

echo "Creating SockShop user accounts"
../utils/create-sockshop-accounts.sh

echo "Configuring Dynatrace environment"
../utils/config-dt-webapps-synth.sh

echo "Start Production carts load"
nohup ../utils/cartsLoadTest.sh &
nohup ../utils/cartsLoadTest.sh &

echo "Deployment Complete"
