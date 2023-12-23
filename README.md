# Terraform

## TODO's

* Collect uprecords for my EC2 instances
* Nextcloud and Bastion: Auto re-create in different AZ on failure.
* Input variables, for configuring different service hosts.
* Enable IPv6
* Use Bastion host to connect to other EC2 instances (internal DNS?)
* Backup EFS, don't let `terraform destroy` erease all my data!

## Create base environment

First create VPC, subnets and EFS in `org-buetow-base`

## Use the bastion to set up some EFS subdirs

Then, create subdirectories in EFS, using `org-buetow-bastion`. E.g., have something like this created:

```shell
[paul@earth]~/git/terraform/org-buetow-bastion% ssh ec2-user@bastion.aws.buetow.org find /mnt
/mnt
/mnt/efs
/mnt/efs/ec2
/mnt/efs/ec2/nextcloud
/mnt/efs/ecs
/mnt/efs/ecs/anki-sync-server
/mnt/efs/ecs/vaultwarden
/mnt/efs/ecs/wallabag
/mnt/efs/ecs/wallabag/data/db
/mnt/efs/ecs/wallabag/data/assets
/mnt/efs/ecs/audiobookshelf
```

## Set up Application loadbalancer

In `org-buetow-elb`

## Now set up Fargate/ECS

In `org-buetow-ecs`

## Nextcloud

In `org-buetow-nextcloud`
