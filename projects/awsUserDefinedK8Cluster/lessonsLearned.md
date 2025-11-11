aws ec2 describe-availability-zones --region us-east-1

# Create subnet in first AZ
aws ec2 create-subnet \
  --vpc-id vpc-0dd23177 \
  --cidr-block 172.31.0.0/20 \
  --availability-zone us-east-1a

# Create subnet in second AZ  
aws ec2 create-subnet \
  --vpc-id vpc-0dd23177 \
  --cidr-block 172.31.16.0/20 \
  --availability-zone us-east-1b

# Add more subnets for additional AZs as needed