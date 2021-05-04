#!/bin/bash

#######################################################################################
# Deploy the Curity Identity Server cluster to Kubernetes, with backed up configuration
#######################################################################################

#
# Point to the minikube profile
#
eval $(minikube docker-env --profile curity)
minikube profile curity
if [ $? -ne 0 ];
then
  echo "Minikube problem encountered - please ensure that the service is started"
  exit 1
fi

#
# Build a custom docker image with some extra resources
#
docker build -f idsvr/Dockerfile -t custom_idsvr:6.1.0 .
if [ $? -ne 0 ];
then
  echo "Problem encountered building the Identity Server custom docker image"
  exit 1
fi

#
# Uninstall the existing system if applicable
#
kubectl delete -f idsvr/idsvr.yaml 2>/dev/null

#
# Create the config map referenced in the helm-values.yaml file
# This deploys XML configuration to containers at /opt/idsvr/etc/init/configmap-config.xml
# - kubectl get configmap idsvr-configmap -o yaml
#
kubectl delete configmap idsvr-configmap 2>/dev/null
kubectl create configmap idsvr-configmap --from-file='./idsvr/idsvr-config-backup.xml'
if [ $? -ne 0 ];
then
  echo "Problem encountered creating the config map for the Identity Server"
  exit 1
fi

#
# Download the Helm Chart
#
helm repo add curity https://curityio.github.io/idsvr-helm
helm repo update
if [ $? -ne 0 ];
then
  echo "Problem encountered downloading the Helm Chart for the Curity Identity Server"
  exit 1
fi

#
# The simple option is to then just run the Helm Chart
# We will instead show how to extract yaml and apply it manually
# - helm install curity curity/idsvr --values=idsvr/helm-values.yaml
#

#
# We will show how to get the complete Kubernetes YAML used when deploying the Identity Server
# This produces an idsvr-helm.yaml file that could then be customized further
#
HELM_FOLDER=~/tmp/idsvr-helm
rm -rf $HELM_FOLDER
git clone https://github.com/curityio/idsvr-helm $HELM_FOLDER
cp idsvr/helm-values.yaml $HELM_FOLDER/idsvr
helm template curity $HELM_FOLDER/idsvr --values $HELM_FOLDER/idsvr/helm-values.yaml > idsvr/idsvr-helm.yaml
if [ $? -ne 0 ];
then
  echo "Problem encountered creating Kubernetes YAML from the Identity Server Helm Chart"
  exit 1
fi

#
# Apply the YAML to deploy the system, though you may prefer to just run the Helm chart directly
# - helm uninstall curity  2>/dev/null
# - helm install curity curity/idsvr --values=idsvr/helm-values.yaml
#
kubectl delete -f idsvr/idsvr-helm.yaml 2>/dev/null
kubectl apply -f idsvr/idsvr-helm.yaml
if [ $? -ne 0 ];
then
  echo "Problem encountered applying Kubernetes YAML"
  exit 1
fi

#
# Once the pods come up we can call them over these URLs externally:
#
# - curl -u 'admin:Password1' 'https://admin.curitylocal.io/admin/api/restconf/data?depth=unbounded&content=config'
# - curl 'https://login.curitylocal.io/oauth/v2/oauth-anonymous/.well-known/openid-configuration'
#
# Inside the cluster we can use these URLs: 
#
# curl -u 'admin:Password1' 'https://curity-idsvr-admin-svc:6749/admin/api/restconf/data?depth=unbounded&content=config'
# curl -k 'https://curity-idsvr-runtime-svc:8443/oauth/v2/oauth-anonymous/.well-known/openid-configuration'
#