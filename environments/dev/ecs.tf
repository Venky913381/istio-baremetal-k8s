# Example of how you would add the ECS module.
# Note: For this to work, you must first define and output 'ecs_security_group_id'
# from your security-groups module.
module "ecs" {
  source = "../../modules/ecs"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.ecs_security_group_id

  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  container_image             = module.ecr.repository_url
  container_port              = 80
  target_group_arn            = module.alb.ecs_target_group_arn
}