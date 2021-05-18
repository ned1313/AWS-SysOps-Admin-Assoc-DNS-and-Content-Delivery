# Now that we have out totally awesome website, let's create an alias record
# in Route 53 for it
route_53_domain="globomanticslabs.com"
bucketname="www.${route_53_domain}"
region=us-east-1

# First get the hosted zone you want to use for the website
# Get all hosted zones
zones=$(aws route53 list-hosted-zones --output json)

# Find the zone ID based on the zone name
# Change zone name as needed
zone_id=$(echo $zones | jq '.HostedZones[] | select(.Name=="globomanticslabs.com.") | .Id' -r | cut -d '/' -f3)

# And we also need the Hosted Zone ID and S3 endpoint for S3
# You can find the correct settings for your region here: https://docs.aws.amazon.com/general/latest/gr/s3.html#s3_website_region_endpoints
hosted_zone_id=Z3AQBSTGFYJSTF
dns_name=s3-website-us-east-1.amazonaws.com

# Create alias file with place holders
cat << EOF > alias_record.json
{
    "Comment": "Add record for static website",
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "$bucketname",
          "Type": "A",
          "AliasTarget": {
              "HostedZoneId": "$hosted_zone_id",
              "DNSName": "$dns_name",
              "EvaluateTargetHealth": true
          }
        }
      }
    ]
  }
EOF

# And finally create our alias record on Route 53
aws route53 change-resource-record-sets --hosted-zone-id $zone_id \
  --change-batch file://alias_record.json