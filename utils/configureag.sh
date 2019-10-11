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

kubectl apply -f ../manifests/dynatrace/kubernetes-monitoring-service-account.yaml

export API_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
export TOKEN=$(kubectl get secret $(kubectl get sa dynatrace-monitoring -o jsonpath='{.secrets[0].name}' -n dynatrace) -o jsonpath='{.data.token}' -n dynatrace | base64 --decode)
export CLUSTER_NAME="acmworkshop"

curl -X POST "$DT_TENANT_URL/api/config/v1/kubernetes/credentials" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token $API_TOKEN" -H "Content-Type: application/json; charset=utf-8" -d "{ \"label\": \"$CLUSTER_NAME\", \"endpointUrl\": \"$API_URL\", \"authToken\": \"$TOKEN\", \"active\": true}"