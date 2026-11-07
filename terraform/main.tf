data "aws_caller_identity" "current" {}

data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

module "acm" {
  source = "./modules/acm"

  project_name   = var.project_name
  environment    = var.environment
  domain_name    = var.domain_name
  hosted_zone_id = data.aws_route53_zone.main.zone_id
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  container_port    = var.container_port
  certificate_arn   = module.acm.certificate_arn
}

module "route53" {
  source = "./modules/route53"

  domain_name    = var.domain_name
  hosted_zone_id = data.aws_route53_zone.main.zone_id
  alb_dns_name   = module.alb.alb_dns_name
  alb_zone_id    = module.alb.alb_zone_id
}

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  aws_account_id      = data.aws_caller_identity.current.account_id
  ecr_repository_name = module.ecr.repository_name
  github_oidc_subject = var.github_oidc_subject
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name            = var.project_name
  environment             = var.environment
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  ecs_cpu_alarm_threshold = 80
  alb_5xx_alarm_threshold = 5

  target_group_arn_suffix            = module.alb.target_group_arn_suffix
  target_5xx_alarm_threshold         = 5
  target_p95_latency_alarm_threshold = 1
}

module "ecs" {
  source = "./modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  task_security_group   = module.networking.ecs_security_group_id
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  execution_role_arn    = module.iam.ecs_execution_role_arn
  task_role_arn         = module.iam.ecs_task_role_arn
  log_group_name        = module.cloudwatch.ecs_log_group_name
  ecr_repository_url    = module.ecr.repository_url
  image_tag             = var.image_tag
  container_port        = var.container_port
  desired_count         = var.desired_count
  cpu                   = var.ecs_cpu
  memory                = var.ecs_memory
}

module "autoscaling" {
  source = "./modules/autoscaling"

  project_name     = var.project_name
  environment      = var.environment
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
  min_capacity     = var.min_capacity
  max_capacity     = var.max_capacity
  cpu_target       = var.cpu_target
  memory_target    = var.memory_target
}