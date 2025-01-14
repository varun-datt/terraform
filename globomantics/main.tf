# Note: Can have individual files that group related resources together (example: data, resource etc., related to load balancers)

## Networking

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws
module "app" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  cidr = var.vpc_cidr_block

  azs = slice(data.aws_availability_zones.available.names, 0, var.vpc_public_subnets_count)
  # Hard coded 8 bits to be added to the CIDR range for the VPC
  public_subnets = [for i in range(var.vpc_public_subnets_count) : cidrsubnet(var.vpc_cidr_block, 8, i)]

  enable_nat_gateway      = false # since we don't have any private subnets and also expensive
  enable_vpn_gateway      = false
  enable_dns_hostnames    = var.vpc_enable_dns_hostnames
  map_public_ip_on_launch = var.vpc_public_subnet_map_public_ip_on_launch

  # https://developer.hashicorp.com/terraform/language/functions/merge
  tags = merge(local.common_tags, { Name = "${local.naming_prefix}-vpc" })
}

/* Below individual vpc, internet gateway, subnets, route table, route table association resources are replaced by the module above
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "app" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  # https://developer.hashicorp.com/terraform/language/functions/merge
  tags = merge(local.common_tags, { Name = "${local.naming_prefix}-vpc" })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

  tags = merge(local.common_tags, { Name = "${local.naming_prefix}-ig" })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "public_subnets" {
  count  = var.vpc_public_subnets_count
  vpc_id = aws_vpc.app.id
  # https://developer.hashicorp.com/terraform/language/functions/cidrsubnet
  cidr_block              = cidrsubnet(aws_vpc.app.cidr_block, 8, count.index)
  map_public_ip_on_launch = var.vpc_public_subnet_map_public_ip_on_launch
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, { Name = "${local.naming_prefix}-public-subnet-${count.index}" })
}

### Networking - Routing

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.app.id

  # default route pointing to the internet gateway: Traffic can get out of the VPC through the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }
  # can add more routes here with additional nested route blocks, similar to the one above

  tags = merge(local.common_tags, { Name = "${local.naming_prefix}-route-table" })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "app_public_subnets" {
  count          = var.vpc_public_subnets_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.app.id
}
*/

### Networking - Load balancer

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "nginx" {
  name               = "${local.naming_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.app.public_subnets
  depends_on         = [module.webapp_s3_iam_profile] # wait for the S3 bucket policy to be created

  enable_deletion_protection = false # Allow Terraform to delete

  # send ALB logs to S3 bucket
  access_logs {
    bucket  = module.webapp_s3_iam_profile.s3_bucket.id
    prefix  = "alb-logs"
    enabled = true
  }

  tags = local.common_tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "nginx" {
  name     = "${local.naming_prefix}-nginx-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.app.vpc_id

  tags = local.common_tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }

  tags = merge(local.common_tags, { Name = "${local.naming_prefix}-alb-listener" })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment
resource "aws_lb_target_group_attachment" "nginx_servers" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = aws_instance.nginx_servers[count.index].id
  port             = 80
}

## Security Groups

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "nginx_sg" {
  name   = "${local.naming_prefix}-nginx-sg"
  vpc_id = module.app.vpc_id

  # traffic from anywhere to talk to port 80 of the EC2 instance
  ingress {
    from_port   = var.security_group_ingress_port
    to_port     = var.security_group_ingress_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] # allow traffic from within the VPC
  }

  # outbound internet access
  egress {
    from_port   = var.security_group_egress_port
    to_port     = var.security_group_egress_port
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "alb_sg" {
  name   = "${local.naming_prefix}-nginx-alb-sg"
  vpc_id = module.app.vpc_id

  # traffic from anywhere to talk to port 80 of the EC2 instance
  ingress {
    from_port   = var.security_group_ingress_port
    to_port     = var.security_group_ingress_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # all zeros cidr - allow traffic from anywhere
  }

  # outbound internet access
  egress {
    from_port   = var.security_group_egress_port
    to_port     = var.security_group_egress_port
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

## EC2 Instances

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "nginx_servers" {
  count                  = var.instance_count
  ami                    = data.aws_ami.main.id
  instance_type          = var.instance_type
  subnet_id              = module.app.public_subnets[(count.index % var.vpc_public_subnets_count)]
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  iam_instance_profile   = module.webapp_s3_iam_profile.instance_profile.name
  depends_on             = [module.webapp_s3_iam_profile]

  tags = merge(
    local.common_tags,
    { Name = "${local.naming_prefix}-nginx-${count.index}" }
  )

  # https://developer.hashicorp.com/terraform/language/functions/templatefile
  # directives: %{if <BOOL>}/%{else}/%{endif} OR %{ for ip in aws_instance.example[*].private_ip } server ${ip} %{ endfor ~}
  user_data = templatefile("${path.module}/templates/startup_script.tpl", {
    s3_bucket_name       = module.webapp_s3_iam_profile.s3_bucket.id
    contents_base_folder = local.website_contents_base_folder
  })
}

## S3 bucket

## Create S3 bucket and IAM role and policy to allow EC2 instances to access the bucket
module "webapp_s3_iam_profile" {
  source                  = "./modules/globomantics-web-s3"
  bucket_name             = local.s3_bucket_name
  elb_service_account_arn = data.aws_elb_service_account.main.arn
  common_tags             = local.common_tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object
resource "aws_s3_object" "website_content" {
  # https://developer.hashicorp.com/terraform/language/expressions/references#filesystem-and-workspace-info
  # https://developer.hashicorp.com/terraform/language/functions/fileset
  for_each = fileset(path.module, "${local.website_contents_base_folder}/*")

  # local or variables to get the file paths: can combine with path expressions to get full path
  # for_each = {
  #   website = "/website/index.html"
  #   logo    = "/website/Globo_logo_Vert.png"
  # }

  bucket = module.webapp_s3_iam_profile.s3_bucket.id
  key    = each.value                     # destination key/path in the S3 bucket
  source = "${path.module}/${each.value}" # source file to upload to the S3 bucket

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${path.module}/${each.value}")

  tags = merge(local.common_tags, { Name = "${local.naming_prefix}-object" })
}
