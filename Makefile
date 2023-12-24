apply:
	cd org-buetow-base && terraform apply -auto-approve
	cd org-buetow-bastion && terraform apply -auto-approve
	cd org-buetow-elb && terraform apply -auto-approve
	cd org-buetow-ecs && terraform apply -auto-approve
	#cd org-buetow-nextcloud && terraform apply -auto-approve
destroy:
	cd org-buetow-nextcloud && terraform destroy -auto-approve
	cd org-buetow-ecs && terraform destroy -auto-approve
	cd org-buetow-elb && terraform destroy -auto-approve
	cd org-buetow-bastion && terraform destroy -auto-approve
recreate: destroy apply
