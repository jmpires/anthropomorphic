# AWS
aws sts get-caller-identity

# Git
# Remove from Git index but keep the local file
git rm --cached terraform.tfvars
# Commit the removal
git commit -m "Stop tracking terraform.tfvars (environment-specific values)"
# Push the change
git push

# Apply hcl file in the init command
terraform init -backend-config=backend.hcl
