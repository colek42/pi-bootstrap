#! /bin/bash


source secrets.env

GIT_HOST=github.com
GIT_USER=colek42

#This shell script bootstraps flux onto a cluster in a Keysight development environment
git_url=`git config --get remote.origin.url`
if [[ $git_url == *"http"* ]]; then
  echo "git origin must not be http or https"
  exit 1
fi

GIT_REPO=`basename -s .git $(git config --get remote.origin.url) | tr -d '\n' | tr -d ' '`
git_url=`echo "ssh://git@${GIT_HOST}/${GIT_USER}/${GIT_REPO}.git"`


export KUBECONFIG=./kubeconfig

#Install helm
# kubectl -n kube-system create sa tiller

# kubectl create clusterrolebinding tiller-cluster-rule \
#     --clusterrole=cluster-admin \
#     --serviceaccount=kube-system:tiller

# helm init --skip-refresh --upgrade --service-account tiller --history-max 10 --wait

# #Inlets
# kubectl create secret generic inlets-access-key \
#   --from-literal inlets-access-key="${DO_TOKEN}"

#External-DNS Secrets

# kubectl create secret generic aws-creds \
#   --from-literal AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
#   --from-literal AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"


##Install flux
helm repo add fluxcd https://charts.fluxcd.io
helm repo update

#TODO Don't hardcode crd version
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flux/helm-0.10.1/deploy-helm/flux-helm-release-crd.yaml

kubectl create ns flux


helm upgrade -i flux \
--set helmOperator.create=true \
--set helmOperator.createCRD=false \
--set helmOperator.repository=registry.gitlab.com/jonohill/flux/helm-operator \
--set helmOperator.tag=0.10.1 \
--set git.url=${git_url} \
--set image.repository=registry.gitlab.com/jonohill/flux/flux \
--set image.tag=1.14.2 \
--namespace flux \
--wait \
fluxcd/flux

#https://github.com/colek42/k3d-bootstrap/settings/keys/new

publickey=`fluxctl identity --k8s-fwd-ns flux`
echo "Please Add the following public key to the repo provider with push/pull permissions"
echo ""
echo ${publickey}