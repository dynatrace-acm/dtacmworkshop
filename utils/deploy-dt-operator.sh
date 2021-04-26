#!/bin/bash

export API_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceApiToken')
export PAAS_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatracePaaSToken')
export TENANTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceTenantID')
export ENVIRONMENTID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceEnvironmentID')

kubectl create namespace dynatrace

wget https://github.com/dynatrace/dynatrace-operator/releases/latest/download/install.sh -O install.sh

sh ./install.sh --api-url "https://$TENANTID.live.dynatrace.com/api" --api-token $API_TOKEN --paas-token $PAAS_TOKEN --enable-volume-storage --skip-ssl-verification

# kubectl apply -f https://github.com/Dynatrace/dynatrace-oneagent-operator/releases/latest/download/kubernetes.yaml

# kubectl -n dynatrace create secret generic oneagent --from-literal="apiToken="$API_TOKEN --from-literal="paasToken="$PAAS_TOKEN

#if [[ -f "cr.yaml" ]]; then
#    rm -f cr.yaml
#    echo "Removed cr.yaml"
#fi

# curl -o cr.yaml https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/master/deploy/cr.yaml

# case $ENVIRONMENTID in
#        '')
#        echo "SaaS Deployment"
#        sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$TENANTID'.live.dynatrace.com\/api/' cr.yaml
#        ;;
#        *)
#        echo "Managed Deployment"
#        sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$TENANTID'.dynatrace-managed.com\/e\/'$ENVIRONMENTID'\/api/' cr.yaml
#        ;;
#        ?)
#        usage
#        ;;
# esac

# kubectl create -f cr.yaml
