kubectl delete -f ./manifests/jenkins/k8s-jenkins-secret.yaml
kubectl delete -f ./manifests/jenkins/k8s-jenkins-rbac.yaml
kubectl delete -f ./manifests/jenkins/k8s-jenkins-deployment.yaml
kubectl delete -f ./manifests/jenkins/k8s-jenkins-pvcs.yaml
kubectl delete -f ./manifests/jenkins/k8s-jenkins-ns.yaml

echo "----------------------------------------------------"
echo "Jenkins has been removed"
echo "----------------------------------------------------"