#! /bin/bash

set -x

user="ubuntu"
password="arc1983*"

declare -a master="172.4.20.2"
declare -a nodes=("172.4.20.10" 
                "172.4.20.11"
                "172.4.20.12"
                )

#Download k3sup
mkdir ./tmp


curl -L -o ./tmp/k3sup https://github.com/alexellis/k3sup/releases/download/0.7.8/k3sup
chmod +x ./tmp/k3sup

ssh-keygen -b 2048 -t rsa -f ./tmp/pi-ssh-key -q -N ""

ssh-keygen -f "/home/nkennedy/.ssh/known_hosts" -R "172.4.20.2"
ssh-keygen -f "/home/nkennedy/.ssh/known_hosts" -R "172.4.20.10"
ssh-keygen -f "/home/nkennedy/.ssh/known_hosts" -R "172.4.20.11"
ssh-keygen -f "/home/nkennedy/.ssh/known_hosts" -R "172.4.20.12"


sshpass -p ${password} ssh -o StrictHostKeyChecking=no ${user}@${master} "rm -f /home/ubuntu/.ssh"
cat ./tmp/pi-ssh-key.pub | sshpass -p ${password} ssh -o StrictHostKeyChecking=no ${user}@${master} 'mkdir ~/.ssh | true && cat >> ~/.ssh/authorized_keys'

new=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c12)

ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "echo ${new} | sudo tee /etc/hostname" 
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo hostname ${new}"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "echo 127.0.0.1 "${new}" | sudo tee /etc/hosts"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "echo 127.0.0.1 localhost | sudo tee -a /etc/hosts"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo /usr/local/bin/k3s-killall.sh"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo /usr/local/bin/k3s-uninstall.sh"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo /usr/local/bin/k3s-agent-uninstall.sh"
ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo init 6"
#ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${master} "sudo sed -i 's#rootwait#rootwait cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory#' /boot/cmdline.txt"



for node in "${nodes[@]}"
do
    sshpass -p ${password} ssh -o StrictHostKeyChecking=no ${user}@${master} "rm -f /home/ubuntu/.ssh"
	cat ./tmp/pi-ssh-key.pub | sshpass -p ${password} ssh -o StrictHostKeyChecking=no ${user}@${node} 'mkdir ~/.ssh | true && cat >> ~/.ssh/authorized_keys'
    
    new=$(tr -dc 'A-Z0-9' < /dev/urandom | head -c12)
    
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "echo ${new} | sudo tee /etc/hostname" 
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo hostname ${new}"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "echo 127.0.0.1 "${new}" | sudo tee /etc/hosts"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "echo 127.0.0.1 localhost | sudo tee -a /etc/hosts"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo /usr/local/bin/k3s-killall.sh"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo /usr/local/bin/k3s-uninstall.sh"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo /usr/local/bin/k3s-agent-uninstall.sh"
    ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "sudo init 6"

    #ssh -i ./tmp/pi-ssh-key -o StrictHostKeyChecking=no ${user}@${node} "echo 'console=serial0,115200 console=tty1 root=PARTUUID=6c586e13-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory'sudo sed -i 's#rootwait#rootwait cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory#' /boot/cmdline.txt"

done

./tmp/k3sup install --ip $master --user ${user} --ssh-key ./tmp/pi-ssh-key --k3s-extra-args "--no-deploy=traefik"

sleep 30

for node in "${nodes[@]}"
do
    ./tmp/k3sup join --ip $node --server-ip $master --user ${user} --ssh-key ./tmp/pi-ssh-key
done


#"cgroup_memory=1 cgroup_enable=memory" 