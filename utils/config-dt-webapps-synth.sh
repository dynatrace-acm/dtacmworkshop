#!/bin/bash

YLW='\033[1;33m'
NC='\033[0m'

TENANT_ID=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceTenantID')
DT_API_URL=https://$TENANT_ID.live.dynatrace.com/api
DT_CONFIG_TOKEN=$(cat ../1-Credentials/creds.json | jq -r '.dynatraceApiToken')
SOCKSHOP_WEBAPP_CONFIG=$(cat ../dynatrace-config/sockshop_webapp_template.json | sed "s/<SOCK_SHOP_WEBAPP_NAME>/Sock Shop - Production/")

AUTOTAG_PRODUCT_CONFIG=$(cat ../dynatrace-config/tagging_rule_product.json)
AUTOTAG_STAGE_CONFIG=$(cat ../dynatrace-config/tagging_rule_stage.json)
SERVICES_ANOMALY_DETECTION_CONFIG=$(cat ../dynatrace-config/services_anomaly_detection_rules.json)


RESPONSE=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Api-Token $DT_CONFIG_TOKEN" -d "$AUTOTAG_PRODUCT_CONFIG" $DT_API_URL/config/v1/autoTags) 
echo $RESPONSE
RESPONSE=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Api-Token $DT_CONFIG_TOKEN" -d "$AUTOTAG_STAGE_CONFIG" $DT_API_URL/config/v1/autoTags)
echo $RESPONSE 
RESPONSE=$(curl -X PUT -H "Content-Type: application/json" -H "Authorization: Api-Token $DT_CONFIG_TOKEN" -d "$SERVICES_ANOMALY_DETECTION_CONFIG" $DT_API_URL/config/v1/anomalyDetection/services)
echo $RESPONSE 


RESPONSE=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Api-Token $DT_CONFIG_TOKEN" -d "$SOCKSHOP_WEBAPP_CONFIG" $DT_API_URL/config/v1/applications/web) 

if [[ $RESPONSE == *"error"* ]]; then
    echo $RESPONSE
else
    PRODUCTION_APPLICATION_ID=$(echo $RESPONSE | grep -oP '(?<="id":")[^"]*')

    #create web app for dev and get id
    SOCKSHOP_WEBAPP_CONFIG=$(cat ../dynatrace-config/sockshop_webapp_template.json | sed "s/<SOCK_SHOP_WEBAPP_NAME>/Sock Shop - Dev/")

    RESPONSE=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Api-Token $DT_CONFIG_TOKEN" -d "$SOCKSHOP_WEBAPP_CONFIG" $DT_API_URL/config/v1/applications/web)
    
    if [[ $RESPONSE == *"error"* ]]; then
    	echo $RESPONSE
    else
        DEV_APPLICATION_ID=$(echo $RESPONSE | grep -oP '(?<="id":")[^"]*')

        #create app detection rules
        PROD_FRONTEND_URL=$(grep "PROD_FRONTEND_URL=" ../utils/configs.txt | sed 's~PROD_FRONTEND_URL=[ \t]*~~')
        DEV_FRONTEND_URL=$(grep "DEV_FRONTEND_URL=" ../utils/configs.txt | sed 's~DEV_FRONTEND_URL=[ \t]*~~')

        PROD_FRONTEND_DOMAIN=$(kubectl describe svc front-end -n production | grep "LoadBalancer Ingress:" | sed 's/LoadBalancer Ingress:[ \t]*//')
        DEV_FRONTEND_DOMAIN=$(kubectl describe svc front-end -n dev | grep "LoadBalancer Ingress:" | sed 's/LoadBalancer Ingress:[ \t]*//')

        #production
        APP_DETECTION_RULE=$(cat ../dynatrace-config/application_detection_rules_template.json | sed "s/<SOCKSHOP_APP_ID>/$PRODUCTION_APPLICATION_ID/" | \
            sed "s/<SOCKSHOP_FRONTEND_DOMAIN>/$PROD_FRONTEND_DOMAIN/")

        RESPONSE=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Api-Token $DT_CONFIG_TOKEN" -d "$APP_DETECTION_RULE" $DT_API_URL/config/v1/applicationDetectionRules)

        #dev
        APP_DETECTION_RULE=$(cat ../dynatrace-config/application_detection_rules_template.json | sed "s/<SOCKSHOP_APP_ID>/$DEV_APPLICATION_ID/" | \
            sed "s/<SOCKSHOP_FRONTEND_DOMAIN>/$DEV_FRONTEND_DOMAIN/")

        RESPONSE=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Api-Token $DT_CONFIG_TOKEN" -d "$APP_DETECTION_RULE" $DT_API_URL/config/v1/applicationDetectionRules)

        if [[ $RESPONSE == *"error"* ]]; then
            echo $RESPONSE
        else
            #create synthetic tests (6)

            USERNAME_PRE=$(grep "SOCKSHOP_USERNAME_PRE=" ../utils/configs.txt | sed 's~SOCKSHOP_USERNAME_PRE=[ \t]*~~')

            SYNTHETIC_CONFIG=$(cat ../dynatrace-config/sockshop_synthetic_template.json | sed "s/<SOCKSHOP_FRONTEND_URL>/http:\/\/$PROD_FRONTEND_DOMAIN:8080/" | sed "s/<SOCKSHOP_WEB_APP_ID>/$PRODUCTION_APPLICATION_ID/" )
	     
            for i in {1..6}
            do
                sleep 10s
		SYNTHETIC_CONFIG_NEW=$(echo $SYNTHETIC_CONFIG | sed "s/<SOCKSHOP_TEST_NAME>/Sock Shop - $i/" | sed "s/<SOCKSHOP_USERNAME>/$USERNAME_PRE$i/")

                RESPONSE=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Api-Token $DT_CONFIG_TOKEN" -d "$SYNTHETIC_CONFIG_NEW" $DT_API_URL/v1/synthetic/monitors)

            done

            if [[ $RESPONSE == *"error"* ]]; then
                echo $RESPONSE
            fi
        fi
    fi
fi


