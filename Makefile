apply:
	cd org-buetow-base && terraform apply -auto-approve
	#cd org-buetow-bastion && terraform apply -auto-approve
	cd org-buetow-elb && terraform apply -auto-approve
	cd org-buetow-ecs && terraform apply -auto-approve
destroy:
	cd org-buetow-ecs && terraform destroy -auto-approve
	cd org-buetow-elb && terraform destroy -auto-approve
	cd org-buetow-eks && terraform destroy -auto-approve
	cd org-buetow-bastion && terraform destroy -auto-approve
sleep:
	@echo 'Waiting for 2 hours.'
	sleep 7200
for2h:	apply sleep destroy
init:
	cd org-buetow-base && terraform init
	cd org-buetow-bastion && terraform init
	cd org-buetow-elb && terraform init
	cd org-buetow-ecs && terraform init
	cd org-buetow-eks && terraform init

recreate: destroy apply
