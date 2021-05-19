# Create a bucket with the necessary website files
route_53_domain="globomanticslabs.com"
bucketname="globo${RANDOM}"
region=us-east-1

# This will create the bucket in us-east-1 by default
# If you want to use another region, add `--create-bucket-configuration LocationConstraint=$region`
aws s3api create-bucket --bucket $bucketname

# Upload an index.html and error.html doc
aws s3 cp index.html s3://$bucketname
aws s3 cp error.html s3://$bucketname

# Create a certificate using ACM for the hosted domain
cert_arn=$(aws acm request-certificate \
  --domain-name $route_53_domain \
  --validation-method DNS \
  --subject-alternative-names "www.${route_53_domain}" \
  --output text)

# Wait for the cert to be validated
aws acm wait certificate-validated --certificate-arn $cert_arn

# Create an OAI for CloudFront

# Update the permissions on S3 using the OAI

# Create a CloudFront distribution for S3

# Create the two alias records in Route 53 for the CloudFront distribution