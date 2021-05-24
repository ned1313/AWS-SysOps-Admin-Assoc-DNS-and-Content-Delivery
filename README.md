# AWS-SysOps-Admin-Assoc-DNS-and-Content-Delivery

Welcome to AWS SysOps Admin Associate: DNS and Content Delivery. I'll admit that's an unwieldy title. These exercise files are meant to accompany my course on Pluralsight.

## Using the Files

Each folder represents a module from the course except for the `setup` folder. You will need a VPC for some of the exercises, and I don't want you to use your default VPC. It's better to have a throwaway VPC that you can experiment with, and I **do** encourage you to experiment beyond the commands laid out in the course. The first thing you'll do is go into the `setup` folder and run the CloudFormation template found within to create your VPC. I used `us-east-1` as my default region. The exercises should work for other regions, just remember the difference in DNS naming and S3 endpoints.

## Pre-requisites

You will want to have the AWS CLI v2.x installed on your system. The commands are all assuming a Linux command line (sorry PowerShell users), so my recommendation is to install WSLv2 if you're running Windows. Personally, I run WSLv2 with an Ubuntu 18.04 instance. There is a practical element on the exam and my assumption is that any CLI tasks will use a similar environment. You'll also need an AWS account and credentials loaded into the CLI configuration. 

In the examples, I go through the process of purchasing a domain from AWS for about $18 USD. You **do not** have to do this. You can buy a domain from [Namecheap](https://www.namecheap.com) or any other registrar for much less. For instance, I just checked and burritosaregood.xyz is available for $1 USD for the first year. Just turn off auto-renew and you won't pay much. Or use an existing domain you might have lying around. Simply create the public hosted zone in Route 53 and update the name servers on your registrar with what Route 53 gives you.

Aside from the domain, the rest of the examples should cost almost no money. S3 storage, domain queries, and CloudFront distributions are all relatively cheap. Make sure you delete everything when you are done.

## Conclusion

I hope you enjoy taking this course and that it helps you pass the new version of the AWS SA-Associate exam! Pass or fail, let me know how you did and if the course helped. You can always find me on Twitter ([ned1313](https://twitter.com/Ned1313)) or on [LinkedIn](https://www.linkedin.com/in/ned-bellavance/).

Thanks and good luck!

Ned
