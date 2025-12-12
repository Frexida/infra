# Remote state backend for platform infrastructure
terraform {
  backend "s3" {
    bucket         = "frexida-terraform-state"
    key            = "platform/self-healing-cicd/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
