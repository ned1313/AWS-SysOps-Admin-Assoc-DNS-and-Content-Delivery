# First we have to create an S3 bucket
# The bucket name MUST match the record you'll use in Route 53
route_53_domain="globomanticslabs.com"
bucketname="www.${route_53_domain}"
region=us-east-1

# This will create the bucket in us-east-1 by default
# If you want to use another region, add `--create-bucket-configuration LocationConstraint=$region`
aws s3api create-bucket --bucket $bucketname

# Upload an index.html and error.html doc
aws s3 cp index.html s3://$bucketname
aws s3 cp error.html s3://$bucketname

# Then we'll add website configuration
aws s3api put-bucket-website --bucket $bucketname --website-configuration file://website.json

# Then we need to enable public access
cat << EOF > public_read.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::$bucketname/*"
            ]
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $bucketname --policy file://public_read.json

# Here's the website's address
echo "$bucketname.s3-website.$region.amazonaws.com"