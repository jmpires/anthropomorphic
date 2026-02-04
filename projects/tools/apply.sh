#!/usr/bin/env bash

terraform fmt
terraform init
terraform validate
terraform test
terraform plan
terraform apply -auto-approve
