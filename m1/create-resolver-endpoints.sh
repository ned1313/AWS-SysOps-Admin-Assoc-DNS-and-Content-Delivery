# You should have already deployed the basic VPC from the setup folder
# and configured your AWS CLI

# Set the region being used
vpc_region=us-east-1

# Let's first get the VPC ID

vpc_id=$(aws ec2 describe-vpcs --filters Name="tag:Name",Values="globo-primary" \
  --query 'Vpcs[0].VpcId' --output text)

# And we'll need two subnet IDs and IP addresses for each endpoint
subnet1_id=$(aws ec2 describe-subnets --filter Name="tag:Name",Values="subnet-1" \
  Name="vpc-id",Values="$vpc_id" --query 'Subnets[0].SubnetId' --output text)

subnet2_id=$(aws ec2 describe-subnets --filter Name="tag:Name",Values="subnet-2" \
  Name="vpc-id",Values="$vpc_id" --query 'Subnets[0].SubnetId' --output text)

# Now we'll create security groups to use with our endpoints

inbound_sg=$(aws ec2 create-security-group --description "inbound-sg-for-resolver" \
  --group-name "ResolverInbound" --vpc-id $vpc_id --output json)

inbound_sg_id=$(echo $inbound_sg | jq .GroupId -r)

outbound_sg=$(aws ec2 create-security-group --description "outbound-sg-for-resolver" \
  --group-name "ResolverOutbound" --vpc-id $vpc_id --output json)

outbound_sg_id=$(echo $outbound_sg | jq .GroupId -r)

# Add allow port 53 on UDP for DNS inbound

aws ec2 authorize-security-group-ingress --group-id $inbound_sg_id \
  --protocol udp --port 53 --cidr "192.168.0.0/16"

# Now we will create our endpoints

aws route53resolver create-resolver-endpoint --name "inbound-globo" \
  --creator-request-id "inbound${RANDOM}" \
  --security-group-ids $inbound_sg_id \
  --direction "INBOUND" \
  --ip-addresses SubnetId=$subnet1_id,Ip="10.0.1.10" SubnetId=$subnet2_id,Ip="10.0.2.10"

aws route53resolver create-resolver-endpoint --name "outbound-globo" \
  --creator-request-id "outbound${RANDOM}" \
  --security-group-ids $outbound_sg_id \
  --direction "OUTBOUND" \
  --ip-addresses SubnetId=$subnet1_id,Ip="10.0.1.11" SubnetId=$subnet2_id,Ip="10.0.2.11"

# Check on resolver creation
aws route53resolver list-resolver-endpoints --filter Name="Name",Values="outbound-globo"

# Get inbound resolver ID
outbound_resolver_id=$(aws route53resolver list-resolver-endpoints \
  --filter Name="Name",Values="outbound-globo" \
  --query 'ResolverEndpoints[0].Id' --output text)

# And a custom rules for inbound

aws route53resolver create-resolver-rule --name "globo-local" \
  --creator-request-id "local${RANDOM}" \
  --rule-type FORWARD \
  --domain-name "globomantics.local" \
  --target-ips="Ip=192.168.0.20" \
  --resolver-endpoint-id $outbound_resolver_id
