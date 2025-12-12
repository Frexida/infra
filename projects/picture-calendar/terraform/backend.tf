# Remote state backend for picture-calendar project
terraform {
  backend "s3" {
    bucket         = "frexida-terraform-state"
    key            = "projects/picture-calendar/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}