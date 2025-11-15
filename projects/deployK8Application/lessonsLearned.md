chmod 600 global-key-pair.pem

ssh -i global-key-pair.pem ec2-user@54.92.129.171 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'


ssh -i global-key-pair.pem ec2-user@54.157.55.223 'sudo systemctl status jenkins'
ssh -i global-key-pair.pem ec2-user@54.157.55.223 'sudo systemctl is-active jenkins'

http://54.92.129.171:8080/

https://plugins.jenkins.io/pipeline-stage-view              # Pipeline <cat > Plugin


aws sts get-caller-identity
aws sts get-caller-identity --profile=<your-profile>


# Edit ~/.zshrc
nano ~/.zshrc
export AWS_PROFILE=jmpires
source ~/.zshrc
echo $AWS_PROFILE  # Should output: jmpires


# 1. Create bucket (replace region if needed)
aws s3 mb s3://<bucket_name> --region <us-east-1>
# 2. Enable versioning
aws s3api put-bucket-versioning \
  --bucket <bucket_name>  \
  --versioning-configuration Status=Enabled
# 3. Block public access
aws s3api put-public-access-block \
  --bucket <bucket_name>  \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true


terraform output ec2_public_ip


# Check Jenkins-specific logs (common locations)
sudo cat /var/log/jenkins/jenkins.log
# If the above doesn't exist, check journalctl for detailed startup errors
sudo journalctl -u jenkins.service --since "5 minutes ago" --no-pager
sudo journalctl -u jenkins.service -n 100 --no-pager


sudo systemctl daemon-reload
sudo systemctl reset-failed jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins


curl -I http://a5f6506ba276644d8a48e7fb0ff52165-654878034.us-east-1.elb.amazonaws.com

aws elb describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancerDescriptions[?DNSName==`<your-elb-name>`].Scheme' \
  --output text

aws elb describe-instance-health \
  --load-balancer-name <your-elb-name> \
  --region us-east-1


aws eks update-kubeconfig --name <cluster_name> --region us-east-1

kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get pods -l app=nginx -o wide
kubectl exec -it $(kubectl get pod -l app=nginx -o jsonpath='{.items[0].metadata.name}') -- curl -I localhost:80
kubectl scale deployment nginx --replicas=2
kubectl get pods -l app=nginx -o wide
aws elb describe-instance-health --load-balancer-name <your-lb-name> --region us-east-1
aws elbv2 describe-load-balancers --region us-east-1 --output table
curl -I http://<new-dns-name>
kubectl get svc nginx -o wide


# GitHub Repo Credentials
+ Manage Jenkins -> Credentials -> System -> Global credentials (unrestricted)
+ Kind -> Username with password
+ Scope -> Global ... + Username + Password

# GitHub AWS Secrets
+ Manage Jenkins -> Credentials -> Stores scoped to Jenkins -> Global credentials (unrestricted)
+ Add Credentials -> Kind -> Secret text -> Secret + ID
Where ID are: 
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
And Secrets need to catch it from ~/.aws/credentials

# GitHub Pipeline Configuration
+ New Item -> jenkins-server -> Pipeline -> OK
+ Pipeline -> Definition -> Pipeline script from SCM
+ SCM -> Git
- Repositories -> Repository URL -> https://github.com/jmpires/anthropomorphic.git
- Credentials -> jmpires/******
- Branches to build -> Branch Specifier (blank for 'any') -> */main
- Script Path -> <path_to_Jenkinsfile> e.g.: projects/deployK8Application/eks/Jenkinsfile
  + current:
  projects/deployK8Application/jenkinsfile/jenkinsApply/Jenkinsfile
  projects/deployK8Application/jenkinsfile/jenkinsDestroyEC2/Jenkinsfile
  projects/deployK8Application/jenkinsfile/jenkinsDestroyEKS/Jenkinsfile

# Troubleshoot access to nginx app
kubectl get svc nginx       # expected to have a value in EXTERNAL-IP
curl -v http://af5422b9b0ca843da81c02aa347dfee8-1191466311.us-east-1.elb.amazonaws.com      # run it inside the ec2 jenkins instance (expected result: 200 OK)

+ if else ...
nslookup af5422b9b0ca843da81c02aa347dfee8-1191466311.us-east-1.elb.amazonaws.com
curl -m 10 http://af5422b9b0ca843da81c02aa347dfee8-1191466311.us-east-1.elb.amazonaws.com

+ Do NOT USE https (unless defined in the nginx deployment. Use http)
http://<alb_address>

# Troubleshooting some leftovers in EKS
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/jenkins-eks-cluster"
aws logs delete-log-group --log-group-name "/aws/eks/jenkins-eks-cluster/cluster"

aws eks update-kubeconfig --name jenkins-eks-cluster --region us-east-1


### Full EKS cli commands deletion
aws eks delete-cluster --name jenkins-eks-cluster --region us-east-1 --profile jmpires

# List and delete any remaining node groups if the cluster deletion didn't handle them
aws eks list-nodegroups --cluster-name jenkins-eks-cluster --region us-east-1 --profile jmpires
# If found, run: aws eks delete-nodegroup --cluster-name jenkins-eks-cluster --nodegroup-name <name> --region us-east-1 --profile jmpires

# Find the VPC ID
aws ec2 describe-vpcs --region us-east-1 --profile jmpires --filters "Name=tag:Name,Values=jenkins-eks-cluster-vpc"
# Or search for the main VPC tag from your Terraform config
aws ec2 describe-vpcs --region us-east-1 --profile jmpires --filters "Name=tag:Name,Values=main-vpc"
# Or use the more generic tag from Terraform AWS module
aws ec2 describe-vpcs --region us-east-1 --profile jmpires --filters "Name=tag:kubernetes.io/cluster/jenkins-eks-cluster,Values=shared"

aws ec2 describe-subnets --region us-east-1 --profile jmpires --filters "Name=vpc-id,Values=vpc-xxxxxxxxx"
# Delete each subnet found (replace subnet IDs)
# aws ec2 delete-subnet --subnet-id subnet-xxxxx --region us-east-1 --profile jmpires
# Repeat for all subnets in the VPC

aws ec2 describe-route-tables --region us-east-1 --profile jmpires --filters "Name=vpc-id,Values=vpc-xxxxxxxxx"
# Delete custom route tables (do NOT delete the main route table association, just the table itself if it's custom and empty of dependencies)
# aws ec2 delete-route-table --route-table-id rtb-xxxxx --region us-east-1 --profile jmpires

aws ec2 describe-internet-gateways --region us-east-1 --profile jmpires --filters "Name=attachment.vpc-id,Values=vpc-xxxxxxxxx"
# Detach and then delete the IGW (replace igw-xxxxx)
# aws ec2 detach-internet-gateway --internet-gateway-id igw-xxxxx --vpc-id vpc-xxxxxxxxx --region us-east-1 --profile jmpires
# aws ec2 delete-internet-gateway --internet-gateway-id igw-xxxxx --region us-east-1 --profile jmpires

aws ec2 describe-nat-gateways --region us-east-1 --profile jmpires --filter "Name=vpc-id,Values=vpc-xxxxxxxxx"
# Find the NAT Gateway ID (e.g., nat-xxxxxxxxx), delete it, and wait for state 'deleted'
# aws ec2 delete-nat-gateway --nat-gateway-id nat-xxxxxxxxx --region us-east-1 --profile jmpires
# Check status: aws ec2 describe-nat-gateways --nat-gateway-ids nat-xxxxxxxxx --region us-east-1 --profile jmpires
# Once 'deleted', also delete the associated Elastic IP if it was created specifically for this NAT.

aws ec2 describe-security-groups --region us-east-1 --profile jmpires --filters "Name=vpc-id,Values=vpc-xxxxxxxxx"
# Delete custom security groups (be careful not to delete default SG or ones used by other resources)
# aws ec2 delete-security-group --group-id sg-xxxxx --region us-east-1 --profile jmpires
# (The EKS-created SGs should be deletable once the cluster is fully gone)

aws ec2 describe-network-interfaces --region us-east-1 --profile jmpires --filters "Name=vpc-id,Values=vpc-xxxxxxxxx"
# Check if any ENIs are 'available' (not attached) or associated with deleted resources, and delete them.
# aws ec2 delete-network-interface --network-interface-id eni-xxxxx --region us-east-1 --profile jmpires

aws ec2 delete-vpc --vpc-id vpc-xxxxxxxxx --region us-east-1 --profile jmpires

aws logs describe-log-groups --log-group-name-prefix "/aws/eks/jenkins-eks-cluster"
aws logs delete-log-group --log-group-name "/aws/eks/jenkins-eks-cluster/cluster"


/aws/lambda/cwsyn-demo-birst-test-daf23d17-5dbe-40a7-92c5-14c02bbf925f
/aws/lambda/cwsyn-my-avatar-test-387bd603-3f20-4e45-bafd-2decc399a2e2


# Find and terminate any running instances in the VPC
INSTANCE_IDS=$(aws ec2 describe-instances --region us-east-1 --profile jmpires --filters "Name=vpc-id,Values=vpc-0f800dbed3b03ff7b" --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' --output text)
if [ -n "$INSTANCE_IDS" ]; then
    echo "Terminating instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region us-east-1 --profile jmpires
    # Wait for termination (optional, but good practice)
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region us-east-1 --profile jmpires
fi