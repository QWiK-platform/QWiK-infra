# iac/base/ecr.tf

# -------------------------
# ECR (Elastic Container Registry)
# -------------------------

# Backend API Repository

resource "aws_ecr_repository" "qwik_api_repo" {
  name                 = "qwik-api-repo-${var.environment}"
  image_tag_mutability = "MUTABLE" # enable tag overwrite

  # Image Scanning for security
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "QWiK-API-Repo-${var.environment}"
    Environment = var.environment
  }
}

# K8s Worker Repository

resource "aws_ecr_repository" "qwik_worker_repo" {
  name                 = "qwik-worker-repo-${var.environment}"
  image_tag_mutability = "MUTABLE" # enable tag overwrite

  # Image Scanning for security
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "QWiK-Worker-Repo-${var.environment}"
    Environment = var.environment
  }
}
