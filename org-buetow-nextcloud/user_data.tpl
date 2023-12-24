#!/bin/bash

# Docker
sudo yum update -y
sudo yum install docker -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user

# EFS
yum install -y amazon-efs-utils
mkdir /mnt/efs
echo '${efs_id}.efs.${region}.amazonaws.com:/ec2/nextcloud /mnt/efs nfs4 defaults,vers=4.1 0 0' >> /etc/fstab
while ! mountpoint /mnt/efs; do
    echo 'Retrying to mount file systems after 10s...'
    mount -a
    sleep 10
done

# Nextcloud
sudo docker run \
    --init \
    -d \
    --sig-proxy=false \
    --name nextcloud-aio-mastercontainer \
    --restart always \
    --publish 8080:8080 \
    --env APACHE_PORT=80 \
    --env APACHE_IP_BINDING=0.0.0.0 \
    --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --env NEXTCLOUD_DATADIR="/mnt/efs/ec2/nextcloud/ncdata" \
    nextcloud/all-in-one:latest
