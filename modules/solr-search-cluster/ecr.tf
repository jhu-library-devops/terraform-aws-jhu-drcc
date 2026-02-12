# ECR repositories and lifecycle policies
resource "aws_ecr_repository" "repositories" {
  for_each = toset(local.ecr_repositories)

  name                 = each.key
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "repositories" {
  for_each   = aws_ecr_repository.repositories
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire untagged images older than 14 days",
        selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 14 },
        action       = { type = "expire" }
      },
      {
        rulePriority = 2,
        description  = "Keep only the last 20 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 20
        },
        action = { type = "expire" }
      }
    ]
  })
}
