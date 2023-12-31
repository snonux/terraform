#!/bin/bash

sudo yum update -y
sudo yum install -y postgresql15 httpd-tools
#sudo amazon-linux-extras install docker -y

# EFS
yum install -y amazon-efs-utils
mkdir /mnt/efs
echo '${efs_id}.efs.${region}.amazonaws.com:/ /mnt/efs nfs4 defaults,vers=4.1 0 0' >> /etc/fstab
while ! mount -a; do
    echo 'Retrying to mount file systems after 10s...'
    sleep 10
done
