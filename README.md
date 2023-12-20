# Terraform

## TODO's

* Nextcloud and Bastion: Auto re-create in different AZ on failure.
* Backup EFS, don't let `terraform destroy` erease all my data!
* Input variables, for configuring different service hosts.
* Maybe register `buetow.rocks` domain (or keep using `aws.buetow.org`)

## Create base environment

First create VPC, subnets and EFS in `org-buetow-base`

## Use the helper to set up some EFS subdirs

Then, create subdirectories in EFS, using `org-buetow-helper`. E.g., have something like this created:

```shell
[paul@earth]~/git/terraform/org-buetow-helper% ssh ec2-user@helper.aws.buetow.org find /mnt
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
