# Remote state backend for homepage project
terraform {
  backend "s3" {
    bucket         = "frexida-terraform-state"
    key            = "projects/homepage/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}