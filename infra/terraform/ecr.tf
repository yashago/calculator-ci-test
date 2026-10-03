resource "aws_ecr_repository" "calculator" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE" # a tag always points to the same image
  force_delete         = true        # demo: let terraform destroy remove it with its images

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "calculator" {
  repository = aws_ecr_repository.calculator.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = { type = "expire" }
    }]
  })
}
