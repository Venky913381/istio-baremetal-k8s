# Container registries for the application images (application/services/*).
locals {
  app_services = ["frontend", "backend", "inventory"]
}

resource "aws_ecr_repository" "app" {
  for_each = toset(local.app_services)

  name                 = "${local.name}/${each.key}"
  image_tag_mutability = "MUTABLE" # allows re-pushing an existing tag
  force_delete         = true      # let terraform destroy remove repos that still hold images
}

# Keep storage cost near zero: only the 5 newest images per repo are kept.
resource "aws_ecr_lifecycle_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}
