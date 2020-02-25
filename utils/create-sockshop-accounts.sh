#!/bin/bash

FRONTEND_URL=$(grep "PROD_FRONTEND_URL=" ../utils/configs.txt | sed 's~PROD_FRONTEND_URL=[ \t]*~~')
USERNAME_PRE=$(grep "SOCKSHOP_USERNAME_PRE=" ../utils/configs.txt | sed 's~SOCKSHOP_USERNAME_PRE=[ \t]*~~') 
PASSWORD=$(grep "SOCKSHOP_PASSWORD=" ../utils/configs.txt | sed 's~SOCKSHOP_PASSWORD=[ \t]*~~') 
EMAIL=$(grep "SOCKSHOP_EMAIL=" ../utils/configs.txt | sed 's~SOCKSHOP_EMAIL=[ \t]*~~') 
FIRSTNAME=$(grep "SOCKSHOP_FIRSTNAME=" ../utils/configs.txt | sed 's~SOCKSHOP_FIRSTNAME=[ \t]*~~') 
LASTNAME_PRE=$(grep "SOCKSHOP_LASTNAME_PRE=" ../utils/configs.txt | sed 's~SOCKSHOP_LASTNAME_PRE=[ \t]*~~')

for i in {0..6}
do
	if [ $i -eq 0 ] 
    	then
		USERNAME=$USERNAME_PRE
		LASTNAME=$LASTNAME_PRE
	else
		USERNAME=$USERNAME_PRE$i
		LASTNAME=$LASTNAME_PRE$i
	fi

	curl "$FRONTEND_URL/register" -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Content-Type: application/json; charset=utf-8' -H 'X-Requested-With: XMLHttpRequest' -H "Origin: $FRONTEND_URL" -H 'Connection: keep-alive' -H "Referer: $FRONTEND_URL/" -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"email\":\"$EMAIL\",\"firstName\":\"$FIRSTNAME\",\"lastName\":\"$LASTNAME\"}"; echo ""
done



