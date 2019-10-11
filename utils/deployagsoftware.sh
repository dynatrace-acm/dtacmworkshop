#!/bin/bash

export DT_TENANT_ID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/tenant_id -H "Metadata-Flavor: Google")
export DT_ENVIRONMENT_ID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/environment_id -H "Metadata-Flavor: Google")
export DT_PAAS_TOKEN=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/paas_token -H "Metadata-Flavor: Google")

if [ -z "$DT_ENVIRONMENT_ID" ]
then
    echo "Environment ID Empty, SaaS Deployment"
    export DT_TENANT_URL="https://$DT_TENANT_ID.live.dynatrace.com"
else
    echo "Environment ID is $DT_ENVIRONMENT_ID, Managed Deployment"
    export DT_TENANT_URL="https://$DT_TENANT_ID.dynatrace-managed.com/e/$DT_ENVIRONMENT_ID"
fi

if [[ -f "Dynatrace-ActiveGate-Linux.sh" ]]; then
    rm -f Dynatrace-ActiveGate-Linux.sh
    echo "Removed Dynatrace-ActiveGate-Linux.sh"
fi

echo "Downloading ActiveGate..."
sudo curl -o Dynatrace-ActiveGate-Linux.sh -X GET "$DT_TENANT_URL/api/v1/deployment/installer/gateway/unix/latest" -H "accept: application/octet-stream" -H "Authorization: Api-Token $DT_PAAS_TOKEN"

if [[ -f "Dynatrace-ActiveGate-Linux.sh" ]]; then
    echo "ActiveGate File is downloaded"
    echo "AG Install Starting..."
    sudo nohup /bin/sh /Dynatrace-ActiveGate-Linux.sh &
    echo "AG Install Complete"
else
    echo "Downloading again..."
    sudo curl -o Dynatrace-ActiveGate-Linux.sh -X GET "$DT_TENANT_URL/api/v1/deployment/installer/gateway/unix/latest" -H "accept: application/octet-stream" -H "Authorization: Api-Token $DT_PAAS_TOKEN"
fi

echo "Waiting for AG to start"
sleep 40

sudo service dynatracegateway start

sleep 20
echo '[http.client.external]' >> /var/lib/dynatrace/gateway/config/custom.properties
echo 'hostname-verification=no' >> /var/lib/dynatrace/gateway/config/custom.properties
echo 'certificate-validation=no' >> /var/lib/dynatrace/gateway/config/custom.properties

sudo service dynatracegateway restart