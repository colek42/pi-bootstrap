#! /bin/bash


export KUBECONFIG=./kubeconfig

#Install helm


##Install flux
helm repo add fluxcd https://charts.fluxcd.io
helm repo update

#TODO Don't hardcode crd version
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/flux-helm-release-crd.yaml

kubectl create ns flux
helm upgrade -i flux fluxcd/flux --wait \
--set git.url=git@github.com:colek42/pi-bootstrap \
--set image.repository=zlangbert/flux \
--set image.tag=cd2677f2-multiarch \
--namespace flux \

helm upgrade -i helm-operator fluxcd/helm-operator --wait \
--namespace flux \
--set git.ssh.secretName=flux-git-deploy \
--set helm.versions=v3 \
--set image.repository=zlangbert/flux-helm-operator \
--set image.tag=25eda677-multiarch


#https://github.com/colek42/k3d-bootstrap/settings/keys/new

publickey=`fluxctl identity --k8s-fwd-ns flux`
echo "Please Add the following public key to the repo provider with push/pull permissions"
echo ""
echo ${publickey}