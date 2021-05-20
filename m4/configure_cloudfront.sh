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

# Create an OAI for CloudFront
oai=$(aws cloudfront create-cloud-front-origin-access-identity \
  --cloud-front-origin-access-identity-config \
  CallerReference="globo-website",Comment="Used for Globo static websites")

oai_id=$(echo $oai | jq .CloudFrontOriginAccessIdentity.Id -r)

# Update the permissions on S3 using the OAI
cat << EOF > bucket_policy.json
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity $oai_id"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$bucketname/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $bucketname \
  --policy file://bucket_policy.json

# Create a certificate using ACM for the hosted domain
cert_arn=$(aws acm request-certificate \
  --domain-name $route_53_domain \
  --validation-method DNS \
  --subject-alternative-names "www.${route_53_domain}" \
  --output text)


# We are going to validate using Route 53 and DNS
# Get all hosted zones
zones=$(aws route53 list-hosted-zones --output json)

# Find the zone ID based on the zone name
# Change zone name as needed
zone_id=$(echo $zones | jq '.HostedZones[] | select(.Name=="globomanticslabs.com.") | .Id' -r | cut -d '/' -f3)

# Now get the validation info from ACM
cert_info=$(aws acm describe-certificate --certificate-arn $cert_arn)
validation_1=$(echo $cert_info | jq .Certificate.DomainValidationOptions[0].ResourceRecord)
validation_2=$(echo $cert_info | jq .Certificate.DomainValidationOptions[1].ResourceRecord)

# We will create a CNAME record for each SAN
cat << EOF > validation_record.json
{
    "Comment": "Add record for static website",
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "$(echo $validation_1 | jq .Name -r)",
          "Type": "CNAME",
          "TTL": 3600,
          "ResourceRecords": [
            {
              "Value": "$(echo $validation_1 | jq .Value -r)"
            }
          ]
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "$(echo $validation_2 | jq .Name -r)",
          "Type": "CNAME",
          "TTL": 3600,
          "ResourceRecords": [
            {
              "Value": "$(echo $validation_2 | jq .Value -r)"
            }
          ]
        }
      }
    ]
  }
EOF

# Create CNAME records and check validation
aws route53 change-resource-record-sets --hosted-zone-id $zone_id \
  --change-batch file://validation_record.json

aws acm wait certificate-validated --certificate-arn $cert_arn

# Create a CloudFront distribution for S3
cat << EOF > cloudfront_config.json
{
    "CallerReference": "cf${RANDOM}",
    "Aliases": {
        "Quantity": 2,
        "Items": [
            "www.${route_53_domain}",
            "$route_53_domain"
        ]
    },
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "${bucketname}.s3.amazonaws.com",
                "DomainName": "${bucketname}.s3.amazonaws.com",
                "OriginPath": "",
                "CustomHeaders": {
                    "Quantity": 0
                },
                "S3OriginConfig": {
                    "OriginAccessIdentity": "origin-access-identity/cloudfront/$oai_id"
                }
            }
        ]
    },
    "OriginGroups": {
        "Quantity": 0
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "${bucketname}.s3.amazonaws.com",
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            },
            "Headers": {
                "Quantity": 0
            },
            "QueryStringCacheKeys": {
                "Quantity": 0
            }
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "AllowedMethods": {
            "Quantity": 2,
            "Items": [
                "GET",
                "HEAD"
            ],
            "CachedMethods": {
                "Quantity": 2,
                "Items": [
                    "GET",
                    "HEAD"
                ]
            }
        },
        "SmoothStreaming": false,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": false,
        "LambdaFunctionAssociations": {
            "Quantity": 0
        },
        "FieldLevelEncryptionId": ""
    },
    "CacheBehaviors": {
        "Quantity": 0
    },
    "CustomErrorResponses": {
        "Quantity": 0
    },
    "Comment": "",
    "Logging": {
        "Enabled": false,
        "IncludeCookies": false,
        "Bucket": "",
        "Prefix": ""
    },
    "PriceClass": "PriceClass_All",
    "Enabled": true,
    "ViewerCertificate": {
        "CloudFrontDefaultCertificate": false,
        "ACMCertificateArn": "$cert_arn",
        "SSLSupportMethod": "sni-only",
        "MinimumProtocolVersion": "TLSv1.2_2019"
    },
    "Restrictions": {
        "GeoRestriction": {
            "RestrictionType": "none",
            "Quantity": 0
        }
    },
    "WebACLId": "",
    "HttpVersion": "http2",
    "IsIPV6Enabled": true
}

EOF

cloudfront_info=$(aws cloudfront create-distribution \
  --distribution-config file://cloudfront_config.json)

# Create the two alias records in Route 53 for the CloudFront distribution

# Get our CloudFront distribution DNS name
cloudfront_dns=$(echo $cloudfront_info | jq .Distribution.DomainName -r)

# Create the alias records file
cat << EOF > alias_record.json
{
    "Comment": "Add records for static website",
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "www.${route_53_domain}",
          "Type": "A",
          "AliasTarget": {
              "HostedZoneId": "Z2FDTNDATAQYW2",
              "DNSName": "$cloudfront_dns",
              "EvaluateTargetHealth": false
          }
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "${route_53_domain}",
          "Type": "A",
          "AliasTarget": {
              "HostedZoneId": "Z2FDTNDATAQYW2",
              "DNSName": "$cloudfront_dns",
              "EvaluateTargetHealth": false
          }
        }
      }
    ]
  }
EOF

# Create the alias records from the file
aws route53 change-resource-record-sets --hosted-zone-id $zone_id \
  --change-batch file://alias_record.json