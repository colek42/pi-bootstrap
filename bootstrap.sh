#! /bin/bash

set -x

user="pi"
password="raspberry"

declare -a master="172.4.20.2"
declare -a nodes=("172.4.20.3" 
                "172.4.20.4"
                "172.4.20.5"
                )

#Download k3sup
mkdir ./tmp


curl -L -o ./tmp/k3sup https://github.com/alexellis/k3sup/releases/download/0.5.12/k3sup
chmod +x ./tmp/k3sup

ssh-keygen -b 2048 -t rsa -f ./tmp/pi-ssh-key -q -N ""


cat ./tmp/pi-ssh-key.pub | sshpass -p ${password} ssh -o StrictHostKeyChecking=no ${user}@${master} 'mkdir ~/.ssh | true && cat >> ~/.ssh/authorized_keys'

new=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c12)

ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "echo ${new} | sudo tee /etc/hostname" 
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo hostname ${new}"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "echo 127.0.0.1 "${new}" | sudo tee /etc/hosts"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo /usr/local/bin/k3s-killall.sh"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo /usr/local/bin/k3s-uninstall.sh"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo /usr/local/bin/k3s-agent-uninstall.sh"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo init 6"
#ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo sed -i 's#rootwait#rootwait cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory#' /boot/cmdline.txt"



for node in "${nodes[@]}"
do
	cat ./tmp/pi-ssh-key.pub | sshpass -p ${password} ssh -o StrictHostKeyChecking=no ${user}@${node} 'mkdir ~/.ssh | true && cat >> ~/.ssh/authorized_keys'
    
    new=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c12)
    
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "echo ${new} | sudo tee /etc/hostname" 
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo hostname ${new}"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "echo 127.0.0.1 "${new}" | sudo tee /etc/hosts"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo /usr/local/bin/k3s-killall.sh"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo /usr/local/bin/k3s-uninstall.sh"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo /usr/local/bin/k3s-agent-uninstall.sh"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo init 6"

    #ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "echo 'console=serial0,115200 console=tty1 root=PARTUUID=6c586e13-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory'sudo sed -i 's#rootwait#rootwait cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory#' /boot/cmdline.txt"

done

./tmp/k3sup install --ip $master --user pi --ssh-key ./tmp/pi-ssh-key --k3s-extra-args "--no-deploy=traefik"

sleep 30

for node in "${nodes[@]}"
do
    ./tmp/k3sup join --ip $node --server-ip $master --user pi --ssh-key ./tmp/pi-ssh-key
done





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
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --skip-refresh --upgrade --service-account tiller --history-max 10 --wait

#Inlets
kubectl create secret generic inlets-access-key \
  --from-literal inlets-access-key="${DO_TOKEN}"

#External-DNS Secrets

kubectl create secret generic aws-creds \
  --from-literal AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
  --from-literal AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"


##Install flux
helm repo add fluxcd https://charts.fluxcd.io
helm repo update

#TODO Don't hardcode crd version
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flux/helm-0.10.1/deploy-helm/flux-helm-release-crd.yaml

helm upgrade -i flux \
--set helmOperator.create=true \
--set helmOperator.createCRD=false \
--set git.url=${git_url} \
--namespace flux \
--wait \
fluxcd/flux

#https://github.com/colek42/k3d-bootstrap/settings/keys/new

publickey=`fluxctl identity --k8s-fwd-ns flux`
echo "Please Add the following public key to the repo provider with push/pull permissions"
echo ""
echo ${publickey}