# Globomantics

## Terraform Configuration
- `terraform plan -var 'aws_access_key=<key>' -var 'aws_secret_key=<key>'`
- OR `TF_VAR_aws_access_key=<key> TF_VAR_aws_secret_key=<key> terraform plan`

## Deployment Architecture
- AWS cloud, 2 tier (web frontend and backend), VPC - subnet - EC2 instance running nginx, routing and security groups for web traffic, ALB

![](./docs/aws-globomantics-deploy-network-architecture.png)

![](./docs/globomantics-deployment-architecture.png)
