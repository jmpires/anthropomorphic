ssh -i jenkins-server.pem ec2-user@54.157.55.223 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword' 


ssh -i jenkins-server.pem ec2-user@54.157.55.223 'sudo systemctl status jenkins'
ssh -i jenkins-server.pem ec2-user@54.157.55.223 'sudo systemctl is-active jenkins'


https://plugins.jenkins.io/pipeline-stage-view              # Pipeline <Stage View> Plugin


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


# GitHub Pipeline configuration
+ New Item -> jenkins-server -> Pipeline -> OK
+ Pipeline -> Definition -> Pipeline script from SCM
+ SCM -> Git
- Repositories -> Repository URL -> https://github.com/jmpires/anthropomorphic.git
- Credentials -> jmpires/******
- Branches to build -> Branch Specifier (blank for 'any') -> */main
- Script Path -> <path_to_Jenkinsfile> e.g.: projects/eks/deployK8Application/Jenkinsfile


# Troubleshoot access to nginx app
kubectl get svc nginx       # expected to have a value in EXTERNAL-IP
curl -v http://af5422b9b0ca843da81c02aa347dfee8-1191466311.us-east-1.elb.amazonaws.com      # run it inside the ec2 jenkins instance (expected result: 200 OK)

+ if else ...
nslookup af5422b9b0ca843da81c02aa347dfee8-1191466311.us-east-1.elb.amazonaws.com
curl -m 10 http://af5422b9b0ca843da81c02aa347dfee8-1191466311.us-east-1.elb.amazonaws.com

+ Do NOT USE https (unless defined in the nginx deployment. Use http)
http://<alb_address>