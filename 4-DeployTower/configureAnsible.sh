#! /bin/bash

export JENKINS_USERNAME=$(kubectl get secret jenkins-secret -n cicd -o yaml | grep "username:" | sed 's~username:[ \t]*~~')
export JENKINS_USERNAME_DECODE=$(echo $JENKINS_USERNAME | base64 --decode)
export JENKINS_PASSWORD=$(kubectl get secret jenkins-secret -n cicd -o yaml | grep "password:" | sed 's~password:[ \t]*~~')
export JENKINS_PASSWORD_DECODE=$(echo $JENKINS_PASSWORD | base64 --decode)

export CART_URL=$(kubectl describe svc carts -n dev | grep "LoadBalancer Ingress:" | sed 's/LoadBalancer Ingress:[ \t]*//')

export DT_TENANT_ID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceTenantID')
export DT_ENVIRONMENT_ID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceEnvironmentID')
export DT_API_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceApiToken')
export DT_PAAS_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatracePaaSToken')

if [ -z "$DT_ENVIRONMENT_ID" ]
then
    echo "Environment ID Empty, SaaS Deployment"
    export DT_TENANT_URL="https://$DT_TENANT_ID.live.dynatrace.com"
else
    echo "Environment ID is $DT_ENVIRONMENT_ID, Managed Deployment"
    export DT_TENANT_URL="https://$DT_TENANT_ID.dynatrace-managed.com/e/$DT_ENVIRONMENT_ID"
fi

export JENKINS_URL=$(kubectl describe svc jenkins -n cicd | grep IP: | sed 's/IP:[ \t]*//')
export TOWER_URL=$(kubectl describe svc ansible-tower -n tower | grep "LoadBalancer Ingress:" | sed 's/LoadBalancer Ingress:[ \t]*//')

export DTAPICREDTYPE=$(curl -k -X POST https://$TOWER_URL/api/v2/credential_types/ --user admin:dynatrace -H "Content-Type: application/json" \
--data '{
  "name": "dt-api",
  "kind": "cloud",
  "description" :"Dynatrace API Authentication Token",
  "inputs": { "fields": [ { "secret": true, "type": "string", "id": "dt_api_token", "label": "Dynatrace API Token" } ], "required": ["dt_api_token"]}, "injectors": { "extra_vars": { "DYNATRACE_API_TOKEN": "{{dt_api_token}}" } }
}' | jq -r '.id')
echo "DTAPICREDTYPE: " $DTAPICREDTYPE

export DTCRED=$(curl -k -X POST https://$TOWER_URL/api/v2/credentials/ --user admin:dynatrace -H "Content-Type: application/json" \
--data '{
  "name": "'$DT_TENANT_ID' API token",
  "credential_type": '$DTAPICREDTYPE',
  "organization": 1,
  "inputs": { "dt_api_token": "'$DT_API_TOKEN'" }
}' | jq -r '.id')
echo "DTCRED: " $DTCRED

export PROJECT_ID=$(curl -k -X POST https://$TOWER_URL/api/v1/projects/ --user admin:dynatrace -H "Content-Type: application/json" \
--data '{
  "name": "self-healing",
  "scm_type": "git",
  "scm_url": "https://github.com/dynatrace-acm/dtacmworkshop.git",
  "scm_branch": "tower",
  "scm_clean": "true"
}' | jq -r '.id')
echo "PROJECT_ID: " $PROJECT_ID

echo "wait for project to initialize..."
sleep 60

export INVENTORY_ID=$(curl -k -X POST https://$TOWER_URL/api/v1/inventories/ --user admin:dynatrace -H "Content-Type: application/json" \
--data '{
  "name": "inventory",
  "type": "inventory",
  "organization": 1,
  "variables": "---\ntenanturl: \"'$DT_TENANT_URL'\"\ncarts_promotion_url: \"http://'$CART_URL'/carts/1/items/promotion\"\ncommentuser: \"Ansible Playbook\"\ntower_user: \"admin\"\ntower_password: \"dynatrace\"\ndtcommentapiurl: \"{{tenanturl}}/api/v1/problem/details/{{pid}}/comments?Api-Token={{DYNATRACE_API_TOKEN}}\"\ndteventapiurl: \"{{tenanturl}}/api/v1/events/?Api-Token={{DYNATRACE_API_TOKEN}}\""
}' | jq -r '.id')
echo "INVENTORY_ID: " $INVENTORY_ID