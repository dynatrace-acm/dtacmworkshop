kubectl create -f ../manifests/ansible-tower/namespace.yml
kubectl create -f ../manifests/ansible-tower/deployment.yml
kubectl create -f ../manifests/ansible-tower/service.yml

echo "Waiting for Ansible Tower to start..."

sleep 60

./configureAnsible.sh