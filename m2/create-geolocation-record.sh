# First let's create health checks for each location
us_east_check=$(aws route53 create-health-check \
  --caller-reference "us-east-1-${RANDOM}" \
  --health-check-config IPAddress=8.8.8.8,Port=443,Type=HTTPS \
  --output json)

eu_west_check=$(aws route53 create-health-check \
  --caller-reference "eu-west-1-${RANDOM}" \
  --health-check-config IPAddress=8.8.4.4,Port=443,Type=HTTPS \
  --output json)

# Now we can create geolocation records
# Update record with health check ids
cp geolocation_records.json geolocation_records_updated.json

# Get health check ids
us_east_check_id=$(echo $us_east_check | jq .HealthCheck.Id -r)
eu_west_check_id=$(echo $eu_west_check | jq .HealthCheck.Id -r)

sed -i "s/US_EAST_CHECK/$us_east_check_id/" geolocation_records_updated.json
sed -i "s/EU_WEST_CHECK/$eu_west_check_id/" geolocation_records_updated.json

aws route53 change-resource-record-sets --hosted-zone-id $zone_id \
  --change-batch file://geolocation_records_updated.json

# See which record you end up with

dig web-geo.globomanticslabs.com

# Try running the command from different instances on AWS 
# or change the resolver server