#!/bin/bash

# Docker
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker enable
sudo service docker start
sudo usermod -a -G docker ec2-user

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# EFS
yum install -y amazon-efs-utils
mkdir /mnt/efs
echo '${efs_id}.efs.${region}.amazonaws.com:/ /mnt/efs nfs4 defaults,vers=4.1 0 0' >> /etc/fstab
while ! mount -a; do
    echo 'Retrying to mount file systems after 10s...'
    sleep 10
done
