module "eks" {
  source = "../../modules/eks"

  project_name     = var.project_name
  environment      = var.environment
  cluster_version  = "1.28"
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn
}