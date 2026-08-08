# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-cluster"
  version  = var.cluster_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    var.cluster_role_arn
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-eks"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.cluster_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = var.instance_types

  tags = {
    Name = "${var.project_name}-${var.environment}-node-group"
  }

  depends_on = [
    aws_eks_cluster.main
  }
}
