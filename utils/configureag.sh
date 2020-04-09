#!/bin/bash

export API_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceApiToken')
export PAAS_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatracePaaSToken')
export TENANTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceTenantID')
export ENVIRONMENTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceEnvironmentID')

addKubernetesCluster()
{
    sed -i 's/DYNATRACE_K8S_CLUSTER_ID/'$1'/' ../1-Credentials/creds.json
}

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
export CONNECTION_CONFIG="{ \"label\": \"$CLUSTER_NAME\", \"endpointUrl\": \"$API_URL\", \"authToken\": \"$TOKEN\", \"active\": true, \"certificateCheckEnabled\": false, \"eventsIntegrationEnabled\": true, \"eventsFieldSelectors\": [{\"label\": \"SockShop-Production\", \"fieldSelector\": \"involvedObject.namespace=production\", \"active\": true}, {\"label\": \"SockShop-Dev\", \"fieldSelector\": \"involvedObject.namespace=dev\", \"active\": true}]}"

ENDPOINTS=$(curl -s "$DT_TENANT_URL/api/config/v1/kubernetes/credentials" -H "accept: application/json" -H "Authorization: Api-Token $API_TOKEN")


 for row in $(echo "${ENDPOINTS}" | jq '.values' | jq -c '.[]'); do

    if [ $(echo $row | jq -c -r ".name") = $CLUSTER_NAME ]
    then
        echo "Cluster already exists... updating configuration"
        ENDPOINT_ID=$(echo $row | jq -c -r ".id")
        curl -X DELETE "$DT_TENANT_URL/api/config/v1/kubernetes/credentials/$ENDPOINT_ID" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token $API_TOKEN" -H "Content-Type:application/json; charset=utf-8"

        #curl -X PUT "$DT_TENANT_URL/api/config/v1/kubernetes/credentials/$ENDPOINT_ID" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token $API_TOKEN" -H "Content-Type: application/json; charset=utf-8" -d "$CONNECTION_CONFIG"
        #exit 0
    fi
 done

CLUSTERID=$(curl -X POST "$DT_TENANT_URL/api/config/v1/kubernetes/credentials" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token $API_TOKEN" -H "Content-Type: application/json; charset=utf-8" -d "$CONNECTION_CONFIG" | jq -r ".id")

addKubernetesCluster $CLUSTERID
