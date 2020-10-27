#!/bin/bash


export API_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceApiToken')
export PAAS_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatracePaaSToken')
export TENANTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceTenantID')
export ENVIRONMENTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceEnvironmentID')
export AG=$(cat ../1-Credentials/creds.json | jq -r '.dynatracactiveGate')

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
echo "Cloud Provider = $CLOUD_PROVIDER"
echo "ActiveGate = $AG"

echo ""
read -p "Is this all correct? (y/n) : " -n 1 -r
echo ""

usage()
{
    echo 'Usage : ./setupenv.sh API_TOKEN PAAS_TOKEN TENANTID ENVIRONMENTID (optional if a SaaS deployment)'
    exit
}

deployGKE()
{
    echo ""
    
    if [ $AG = 'Y' ] || [ $AG = 'y' ]
    then
        echo "Creating ActiveGate VM..."
        gcloud compute instances create dtactivegate --zone=us-central1-a --machine-type=n1-standard-2 --metadata=tenant_id=$TENANTID,environment_id=$ENVIRONMENTID,paas_token=$PAAS_TOKEN --metadata-from-file startup-script=../utils/deployagsoftware.sh --image=debian-9-stretch-v20190916 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=dtactivegate --reservation-affinity=any
    fi

    echo "Creating GKE Cluster..."

    gcloud container clusters create acmworkshop --zone=us-central1-a --num-nodes=3 --cluster-version "1.15.12-gke.6001" --machine-type=n1-highmem-2 --image-type=Ubuntu

    kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
}

deployAKS()
{
    echo "Creating AKS Cluster..."
    export AKS_RESOURCE_GROUP=ACM
    export AKS_CLUSTER_NAME=acmworkshop

    az group create --name $AKS_RESOURCE_GROUP --location centralus
    az aks create --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --node-count 1 --node-vm-size Standard_B4ms --generate-ssh-keys

    az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME
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

sleep 120

echo "Start Production Load"
nohup ../utils/cartsLoadTest.sh &

case $CLOUD_PROVIDER in
        GKE)
        if [ $AG = 'Y' ] || [ $AG = 'y' ]
        then
            echo "Configuring ActiveGate K8s..."
            ../utils/configureag.sh
            ../utils/configureK8sDashboard.sh
        fi
        echo "-----------------------"
        echo "Deployment Complete"
        echo "-----------------------"
        ;;
        AKS)
        echo "-----------------------"
        echo "Deployment Complete"
        echo "-----------------------"
        ;;
        *)
        echo "-----------------------"
        echo "Deployment Complete"
        echo "-----------------------"
        ;;
    esac




