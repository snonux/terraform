# Terraform

## TODO's

* Cloudwatch monitoring with E-Mail alert of the services.

## Manual steps

### Create `fluxdb_password` 

Go to AWS Secrets manager manually and create it!

### Domain Domain TLS certificate

Create DNS zone and TLS certificate in AWS manually. E.g. create `buetow.cloud` zone and a TLS certificate for `buetow.cloud,*.buetow.cloud`. Add the Certificate ARN to the `org-buetow-base`'s output as `zone_certificate_arn`. 

## Create base environment

Then, create VPC, subnets and EFS in `org-buetow-base`.

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

Also, manually activate daily EFS backup via AWS console.

## Set up Application loadbalancer

In `org-buetow-elb`

## Now set up Fargate/ECS

In `org-buetow-ecs`
