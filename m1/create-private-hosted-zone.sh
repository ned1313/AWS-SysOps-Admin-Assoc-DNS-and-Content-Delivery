# You should have already deployed the basic VPC from the setup folder
# and configured your AWS CLI

# Set the region being used
vpc_region=us-east-1

# Let's first get the VPC ID

vpc_id=$(aws ec2 describe-vpcs --filters Name="tag:Name",Values="globo-primary" \
  --query 'Vpcs[0].VpcId' --output text)

# Now we will create a new private hosted zone and associate it with the VPC
zone_info=$(aws route53 create-hosted-zone --name "globomantics.xyz" \
  --vpc VPCRegion=$vpc_region,VPCId=$vpc_id \
  --caller-reference "webrecord${RANDOM}" --output json)

# Get the zone ID from the returned JSON
zone_id=$(echo $zone_info | jq .HostedZone.Id -r | cut -d '/' -f3)

# And let's add an A record for a web server
aws route53 change-resource-record-sets --hosted-zone-id $zone_id \
  --change-batch file://record.json