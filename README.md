# Terraform

First create VPC, subnets and EFS in `org-buetow-production`

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
/mnt/efs/ecs/audiobookshelf
```
