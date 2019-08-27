export CARTS_IP=$(kubectl describe svc carts -n dev | grep 'LoadBalancer Ingress:' | sed 's~LoadBalancer Ingress:[ \t]*~~')
#export CARTS_URL="http:\/\/"$CARTS_IP":8080\/cart"

sed -i "s/CARTS_URL_PLACEHOLDER/$CARTS_IP/g" carts_load1.jmx
sed -i "s/CARTS_URL_PLACEHOLDER/$CARTS_IP/g" carts_load2.jmx