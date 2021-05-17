# Get all hosted zones
zones=$(aws route53 list-hosted-zones --output json)

# Find the zone ID based on the zone name
# Change zone name as needed
zone_id=$(echo $zones | jq '.HostedZones[] | select(.Name=="globomanticslabs.com.") | .Id' -r | cut -d '/' -f3)

# And let's add an A record for a web server using a simple A record
aws route53 change-resource-record-sets --hosted-zone-id $zone_id \
  --change-batch file://simple_record.json

# Do a simpe query
dig web-simple.globomanticslabs.com

# What if we wanted to create an alias?

# First we can create an application load balancer

# Let's get the VPC ID

vpc_id=$(aws ec2 describe-vpcs --filters Name="tag:Name",Values="globo-primary" \
  --query 'Vpcs[0].VpcId' --output text)

# The load balancer needs a security group

sg=$(aws ec2 create-security-group --description "allow-http-anywhere" \
  --group-name "allow-http-anywhere" --vpc-id $vpc_id)

sg_id=$(echo $sg | jq .GroupId -r)

# Create an ALB for the public subnets

public_subnets=$(aws ec2 describe-subnets --filter Name="tag:Network",Values="Public" \
  Name="vpc-id",Values="$vpc_id" --query 'Subnets[].SubnetId' --output text)

alb=$(aws elbv2 create-load-balancer --name globo-web \
  --subnets $public_subnets \
  --security-groups $sg_id \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4)

# Perfect, now let's go create it in the portal

# If want to do it from the command line, I leave that as a challenge to you!

dig web-load.globomanticslabs.com