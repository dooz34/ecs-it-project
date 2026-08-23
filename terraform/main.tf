data "aws_route53_zone" "main" {
  name = var.hosted_zone_name
}
data "aws_lb_hosted_zone_id" "main" {}
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}
module "acm" {
  source         = "./modules/acm"
  project_name   = var.project_name
  domain_name    = var.domain_name
  hosted_zone_id = data.aws_route53_zone.main.zone_id
}
module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  app_port          = var.app_port
  certificate_arn   = module.acm.certificate_arn
}
module "ecs" {
  source                = "./modules/ecs"
  project_name          = var.project_name
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  app_port              = var.app_port
  container_image       = var.container_image
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
}
module "route53" {
  source         = "./modules/route53"
  hosted_zone_id = data.aws_route53_zone.main.zone_id
  domain_name    = var.domain_name
  alb_dns_name   = module.alb.alb_dns_name
  alb_zone_id    = data.aws_lb_hosted_zone_id.main.id
}
module "github_oidc" {
  source      = "./modules/oidc"
  github_repo = "dooz34/ecs-it-project"
}
output "github_actions_role_arn" {
  value = module.github_oidc.role_arn
}
# PR verification test