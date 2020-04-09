#!/bin/bash

export API_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceApiToken')
export PAAS_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatracePaaSToken')
export TENANTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceTenantID')
export ENVIRONMENTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceEnvironmentID')

if [ -z "$DT_ENVIRONMENT_ID" ]
then
    echo "Environment ID Empty, SaaS Deployment"
    export DT_TENANT_URL="https://$TENANTID.live.dynatrace.com"
else
    echo "Environment ID is $DT_ENVIRONMENT_ID, Managed Deployment"
    export DT_TENANT_URL="https://$TENANTID.dynatrace-managed.com/e/$ENVIRONMENTID"
fi

export API_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
export TOKEN=$(kubectl get secret $(kubectl get sa dynatrace-monitoring -o jsonpath='{.secrets[0].name}' -n dynatrace) -o jsonpath='{.data.token}' -n dynatrace | base64 --decode)
export CLUSTER_NAME="acmworkshop"


ENDPOINTS=$(curl -s "$DT_TENANT_URL/api/config/v1/kubernetes/credentials" -H "accept: application/json" -H "Authorization: Api-Token $API_TOKEN")


 for row in $(echo "${ENDPOINTS}" | jq '.values' | jq -c '.[]'); do

    if [ $(echo $row | jq -c -r ".name") = $CLUSTER_NAME ]
    then
        echo "Deleting Kubernetes Configuration..."
        ENDPOINT_ID=$(echo $row | jq -c -r ".id")
        curl -X DELETE "$DT_TENANT_URL/api/config/v1/kubernetes/credentials/$ENDPOINT_ID" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token $API_TOKEN" -H "Content-Type:application/json; charset=utf-8"
        echo "Kubernetes Configuration Deleted..."
        exit 0
    fi
 done